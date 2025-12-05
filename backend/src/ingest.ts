import axios from 'axios';
import * as admin from 'firebase-admin';
import { FirestoreGame, FirestoreTeam, NHLScheduleResponse, NHLStandingsResponse, TeamSummary } from './types';
import * as path from 'path';

// --- 1. Setup Firebase ---
const serviceAccountPath = path.resolve(__dirname, '../serviceAccountKey.json');

try {
    const serviceAccount = require(serviceAccountPath);
    if (admin.apps.length === 0) {
        admin.initializeApp({
            credential: admin.credential.cert(serviceAccount)
        });
    }
} catch (error) {
    console.error("ERROR: Could not find serviceAccountKey.json!");
    process.exit(1);
}

const db = admin.firestore();
const NHL_API_BASE = "https://api-web.nhle.com/v1";

// Memory storage
let teamGameHistory: Record<string, any[]> = {};
let teamRecordsMap: Record<string, any> = {};

async function main() {
    console.log("🏒 Starting NHL Smart Ingestor...");

    while (true) {
        try {
            console.log("\n--- 🔄 Cycle Start: " + new Date().toLocaleTimeString() + " ---");

            // Reset memory for this cycle to ensure fresh data
            teamGameHistory = {};
            teamRecordsMap = {};

            // STEP 1: Fetch Standings (Get Records for the Game Cards)
            await fetchStandingsInMemory();

            // STEP 2: Fetch Games (Save Games + Build History)
            const status = await ingestGamesAndBuildHistory();

            // STEP 3: Save Teams (Now we have Records AND History)
            await saveTeamProfiles();

            // Sleep Logic
            if (status.live || status.pending) {
                const reason = status.live ? "LIVE GAME" : "PENDING START";
                console.log(`🔥 ${reason}! Refreshing in 1 minute...`);
                await sleep(60 * 1000);
            }
            else if (status.nextStart) {
                const now = new Date();
                const diffMs = status.nextStart.getTime() - now.getTime();
                const wakeUpMs = diffMs - (5 * 60 * 1000);

                if (wakeUpMs > 0) {
                    const maxSleep = 4 * 60 * 60 * 1000;
                    const sleepTime = Math.min(wakeUpMs, maxSleep);
                    const minutes = (sleepTime / 60000).toFixed(0);
                    console.log(`💤 Next game: ${status.nextStart.toLocaleTimeString()}. Sleeping ~${minutes} mins...`);
                    await sleep(sleepTime);
                } else {
                    console.log("⚡ Game starting soon! Sleeping 1 minute...");
                    await sleep(60 * 1000);
                }
            }
            else {
                console.log("💤 No games imminent. Sleeping 1 hour...");
                await sleep(60 * 60 * 1000);
            }

        } catch (error) {
            console.error("❌ Fatal Error in loop:", error);
            await sleep(60000);
        }
    }
}

// --- Helper Functions ---

// Step 1: Just get the records
async function fetchStandingsInMemory() {
    // console.log("... Step 1: Fetching Standings");
    const url = `${NHL_API_BASE}/standings/now`;
    const response = await axios.get<NHLStandingsResponse>(url);

    for (const record of response.data.standings) {
        const abbrev = record.teamAbbrev.default;
        // Store entire record object + formatted string
        teamRecordsMap[abbrev] = {
            recordString: `${record.wins}-${record.losses}-${record.otLosses}`,
            raw: record
        };
    }
    console.log(`   -> Memorized records for ${Object.keys(teamRecordsMap).length} teams.`);
}

// Step 2: Save Games and Build History
async function ingestGamesAndBuildHistory(): Promise<{ live: boolean, pending: boolean, nextStart: Date | null }> {
    console.log("... Step 2: Fetching Schedule & Saving Games");

    let liveGameFound = false;
    let pendingGameFound = false;
    let nextScheduledGame: Date | null = null;
    const now = new Date();

    const datesToFetch: string[] = [];
    for (let i = -7; i <= 7; i++) {
        const d = new Date();
        d.setDate(d.getDate() - i);
        datesToFetch.push(d.toISOString().split('T')[0]);
    }

    const batch = db.batch();
    let operationCount = 0;

    for (const date of datesToFetch) {
        try {
            const url = `${NHL_API_BASE}/schedule/${date}`;
            const response = await axios.get<NHLScheduleResponse>(url);

            const dayData = response.data.gameWeek.find(d => d.date === date);
            if (!dayData || !dayData.games) continue;

            for (const game of dayData.games) {
                const status = mapGameStatus(game.gameState);
                if (status === 'Live') liveGameFound = true;

                const gameStart = new Date(game.startTimeUTC);

                // Check for pending games: Scheduled but start time is in the past
                if (status === 'Scheduled' && gameStart <= now) {
                    pendingGameFound = true;
                }

                if (gameStart > now) {
                    if (!nextScheduledGame || gameStart < nextScheduledGame) {
                        nextScheduledGame = gameStart;
                    }
                }

                // Get record from Step 1
                const homeRecord = teamRecordsMap[game.homeTeam.abbrev]?.recordString || "";
                const awayRecord = teamRecordsMap[game.awayTeam.abbrev]?.recordString || "";
                const venueName = game.venue?.default || "Venue TBD";

                const firestoreGame: FirestoreGame = {
                    gameId: game.id.toString(),
                    startTime: game.startTimeUTC,
                    status: status,
                    venue: venueName,
                    broadcasts: "",
                    homeTeam: {
                        id: game.homeTeam.id,
                        name: game.homeTeam.placeName.default,
                        abbrev: game.homeTeam.abbrev,
                        score: game.homeTeam.score || 0,
                        logo: game.homeTeam.logo,
                        record: homeRecord
                    },
                    awayTeam: {
                        id: game.awayTeam.id,
                        name: game.awayTeam.placeName.default,
                        abbrev: game.awayTeam.abbrev,
                        score: game.awayTeam.score || 0,
                        logo: game.awayTeam.logo,
                        record: awayRecord
                    },
                    apiRaw: game
                };

                const gameRef = db.collection('games').doc(firestoreGame.gameId);
                batch.set(gameRef, firestoreGame, { merge: true });
                operationCount++;

                // Build History (In Memory)
                if (status === 'Final') {
                    addToHistory(game.homeTeam.abbrev, firestoreGame, 'home');
                    addToHistory(game.awayTeam.abbrev, firestoreGame, 'away');
                }

                if (operationCount >= 400) {
                    await batch.commit();
                    operationCount = 0;
                }
            }

        } catch (err) {
            // console.error(`Failed: ${date}`);
        }
    }

    if (operationCount > 0) {
        await batch.commit();
        console.log(`   -> Updated ${operationCount} games.`);
    }

    return { live: liveGameFound, pending: pendingGameFound, nextStart: nextScheduledGame };
}

// Step 3: Write the Teams (Now using the history from Step 2)
async function saveTeamProfiles() {
    console.log("... Step 3: Saving Team Profiles (with History)");
    const batch = db.batch();
    let count = 0;

    // Iterate through the records we fetched in Step 1
    for (const [abbrev, data] of Object.entries(teamRecordsMap)) {
        const recordData = data as any;

        // Get the history we built in Step 2
        const rawHistory = teamGameHistory[abbrev] || [];

        // Sort newest first
        const last5Games = rawHistory
            .sort((a, b) => new Date(b.date).getTime() - new Date(a.date).getTime())
            .slice(0, 5);

        const teamData: FirestoreTeam = {
            teamId: abbrev,
            name: recordData.raw.teamName.default || recordData.raw.teamAbbrev.default,
            record: recordData.recordString,
            logo: `https://assets.nhle.com/logos/nhl/svg/${abbrev}_light.svg`,
            last5Games: last5Games
        };

        const teamRef = db.collection('teams').doc(abbrev);
        batch.set(teamRef, teamData, { merge: true });
        count++;
    }

    if (count > 0) {
        await batch.commit();
        console.log(`   -> Updated ${count} team profiles.`);
    }
}

// --- Utils ---

function mapGameStatus(apiStatus: string): string {
    if (apiStatus === "OFF" || apiStatus === "FINAL") return "Final";
    if (apiStatus === "LIVE" || apiStatus === "CRIT") return "Live";
    return "Scheduled";
}

function addToHistory(teamAbbrev: string, game: FirestoreGame, side: 'home' | 'away') {
    if (!teamGameHistory[teamAbbrev]) teamGameHistory[teamAbbrev] = [];
    const exists = teamGameHistory[teamAbbrev].some(g => g.gameId === game.gameId);
    if (exists) return;

    let result = 'Scheduled';
    const isHome = side === 'home';
    const myScore = isHome ? game.homeTeam.score : game.awayTeam.score;
    const oppScore = isHome ? game.awayTeam.score : game.homeTeam.score;
    const opponent = isHome ? game.awayTeam.abbrev : game.homeTeam.abbrev;

    // Use specific vs/@ logic
    const opponentDisplay = isHome ? `vs ${opponent}` : `@ ${opponent}`;

    if (game.status === 'Final') {
        if (myScore > oppScore) result = 'W';
        else if (myScore < oppScore) result = 'L';
        else result = 'T';
    }

    teamGameHistory[teamAbbrev].push({
        gameId: game.gameId,
        date: game.startTime,
        opponent: opponentDisplay, // e.g. "vs BOS"
        score: `${myScore}-${oppScore}`,
        outcome: result
    });
}

function sleep(ms: number) {
    return new Promise(resolve => setTimeout(resolve, ms));
}

main();