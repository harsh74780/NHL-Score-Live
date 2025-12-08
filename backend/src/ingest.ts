import * as dotenv from 'dotenv';
dotenv.config();
import axios from 'axios';
import { FirestoreGame, FirestoreTeam, HistoryGame } from './types';
import { fetchStandings, fetchSchedule } from './services/nhlApi';
import { initFirestore, batchSaveGames, batchSaveTeams } from './services/db';
import { sleep, mapGameStatus } from './utils/helpers';

// Initialize DB
initFirestore();

// Memory storage
let teamGameHistory: Record<string, HistoryGame[]> = {};
let teamRecordsMap: Record<string, { recordString: string, raw: any }> = {};

async function main() {
    console.log("🏒 Starting NHL Smart Ingestor...");

    let lastFullFetch = 0;
    const FULL_FETCH_INTERVAL = 60 * 60 * 1000; // 1 hour

    while (true) {
        try {
            const now = Date.now();
            const isFullFetch = (now - lastFullFetch > FULL_FETCH_INTERVAL);

            console.log(`\n--- 🔄 Cycle Start: ${new Date().toLocaleTimeString()} (${isFullFetch ? 'Full' : 'Partial'} Fetch) ---`);

            // Reset memory ONLY for Full Fetch (every hour) to rebuild history
            if (isFullFetch) {
                console.log("   -> Clearing history cache for full rebuild...");
                teamGameHistory = {};
            }

            // STEP 1: Fetch Standings
            teamRecordsMap = await fetchStandings();

            // STEP 2: Fetch Games & Build History
            // If partial, only fetch today (range=0). If full, fetch +/- 7 days.
            const range = isFullFetch ? 7 : 0;
            const status = await ingestGamesAndBuildHistory(range);

            if (isFullFetch) lastFullFetch = now;

            // STEP 3: Save Teams
            await saveTeamProfiles();

            // Sleep Logic
            if (status.live || status.pending) {
                const reason = status.live ? "LIVE GAME" : "PENDING START";
                console.log(`🔥 ${reason}! Refreshing in 1 minute...`);
                await sleep(60 * 1000);
            }
            else if (status.nextStart) {
                const nowObj = new Date();
                const diffMs = status.nextStart.getTime() - nowObj.getTime();
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

async function ingestGamesAndBuildHistory(dayRange: number = 7): Promise<{ live: boolean, pending: boolean, nextStart: Date | null }> {
    console.log(`... Step 2: Fetching Schedule & Saving Games (Range: +/- ${dayRange} days)`);

    let liveGameFound = false;
    let pendingGameFound = false;
    let nextScheduledGame: Date | null = null;
    const now = new Date();

    const datesToFetch: string[] = [];
    for (let i = -dayRange; i <= dayRange; i++) {
        const d = new Date();
        d.setDate(d.getDate() - i);
        datesToFetch.push(d.toISOString().split('T')[0]);
    }

    let gamesToSave: FirestoreGame[] = [];

    for (const date of datesToFetch) {
        const dayData = await fetchSchedule(date);
        const dailyGames = dayData?.gameWeek.find(d => d.date === date)?.games;

        if (!dailyGames) continue;

        for (const game of dailyGames) {
            const status = mapGameStatus(game.gameState);
            if (status === 'Live') liveGameFound = true;

            const gameStart = new Date(game.startTimeUTC);

            if (status === 'Scheduled' && gameStart <= now) {
                pendingGameFound = true;
            }

            if (gameStart > now) {
                if (!nextScheduledGame || gameStart < nextScheduledGame) {
                    nextScheduledGame = gameStart;
                }
            }

            const homeRecord = teamRecordsMap[game.homeTeam.abbrev]?.recordString || "";
            const awayRecord = teamRecordsMap[game.awayTeam.abbrev]?.recordString || "";
            const venueName = game.venue?.default || "Venue TBD";

            // Extract Broadcasts
            const broadcasts = game.tvBroadcasts?.map((b: any) => b.network).join(", ") || "";

            // Extract Winning Scorer (if exists)
            const winningGoalScorer = game.winningGoalScorer?.lastName?.default;

            // Extract Game Clock/Period (for Live games)
            let periodDescriptor = "";
            let gameClock = "";

            if (game.periodDescriptor) {
                // e.g. number: 1, periodType: 'REG'
                const p = game.periodDescriptor;
                periodDescriptor = p.periodType === 'OT' ? 'OT' : p.periodType === 'SO' ? 'SO' : `P${p.number}`;
            }

            if (game.clock) {
                // e.g. timeRemaining: "12:34", inIntermission: false
                gameClock = game.clock.inIntermission ? "Intermission" : game.clock.timeRemaining;
            }

            const firestoreGame: FirestoreGame = {
                gameId: game.id.toString(),
                startTime: game.startTimeUTC,
                status: status,
                venue: venueName,
                broadcasts: broadcasts,
                winningGoalScorer: winningGoalScorer,
                periodDescriptor: periodDescriptor,
                gameClock: gameClock,
                homeTeam: {
                    id: game.homeTeam.id,
                    name: game.homeTeam.placeName.default,
                    abbrev: game.homeTeam.abbrev,
                    score: game.homeTeam.score || 0,
                    logo: getEspnLogoUrl(game.homeTeam.abbrev),
                    record: homeRecord
                },
                awayTeam: {
                    id: game.awayTeam.id,
                    name: game.awayTeam.placeName.default,
                    abbrev: game.awayTeam.abbrev,
                    score: game.awayTeam.score || 0,
                    logo: getEspnLogoUrl(game.awayTeam.abbrev),
                    record: awayRecord
                },
                apiRaw: game
            };

            gamesToSave.push(firestoreGame);

            if (status === 'Final') {
                addToHistory(game.homeTeam.abbrev, firestoreGame, 'home');
                addToHistory(game.awayTeam.abbrev, firestoreGame, 'away');
            }
        }
    }

    if (gamesToSave.length > 0) {
        // Save in chunks of 400 to avoid batch limits
        const chunkSize = 400;
        for (let i = 0; i < gamesToSave.length; i += chunkSize) {
            await batchSaveGames(gamesToSave.slice(i, i + chunkSize));
        }
        console.log(`   -> Updated ${gamesToSave.length} games.`);
    }

    return { live: liveGameFound, pending: pendingGameFound, nextStart: nextScheduledGame };
}

async function saveTeamProfiles() {
    console.log("... Step 3: Saving Team Profiles (with History)");

    let teamsToSave: FirestoreTeam[] = [];

    for (const [abbrev, data] of Object.entries(teamRecordsMap)) {
        const recordData = data;
        const rawHistory = teamGameHistory[abbrev] || [];

        const last5Games = rawHistory
            .sort((a, b) => new Date(b.date).getTime() - new Date(a.date).getTime())
            .slice(0, 5);

        const teamData: FirestoreTeam = {
            teamId: abbrev,
            name: recordData.raw.teamName.default || recordData.raw.teamAbbrev.default,
            record: recordData.recordString,
            logo: await fetchSvgAsBase64(abbrev),
            last5Games: last5Games
        };

        teamsToSave.push(teamData);
    }

    if (teamsToSave.length > 0) {
        await batchSaveTeams(teamsToSave);
        console.log(`   -> Updated ${teamsToSave.length} team profiles.`);
    }
}

function addToHistory(teamAbbrev: string, game: FirestoreGame, side: 'home' | 'away') {
    if (!teamGameHistory[teamAbbrev]) teamGameHistory[teamAbbrev] = [];
    if (!teamGameHistory[teamAbbrev]) teamGameHistory[teamAbbrev] = [];
    // Removed early return to allow updates

    let result = 'Scheduled';
    const isHome = side === 'home';
    const myScore = isHome ? game.homeTeam.score : game.awayTeam.score;
    const oppScore = isHome ? game.awayTeam.score : game.homeTeam.score;
    const opponent = isHome ? game.awayTeam.abbrev : game.homeTeam.abbrev;

    const opponentDisplay = isHome ? `vs ${opponent}` : `@ ${opponent}`;

    if (game.status === 'Final') {
        if (myScore > oppScore) result = 'W';
        else if (myScore < oppScore) result = 'L';
        else result = 'T';
    }

    const opponentLogo = isHome ? game.awayTeam.logo : game.homeTeam.logo;

    const newHistoryItem: HistoryGame = {
        gameId: game.gameId,
        date: game.startTime,
        opponent: opponentDisplay,
        opponentLogo: opponentLogo,
        score: `${myScore}-${oppScore}`,
        outcome: result
    };

    const existingIndex = teamGameHistory[teamAbbrev].findIndex(g => g.gameId === game.gameId);
    if (existingIndex !== -1) {
        // Update existing entry (e.g. score changed, game went final)
        teamGameHistory[teamAbbrev][existingIndex] = newHistoryItem;
    } else {
        // Add new entry
        teamGameHistory[teamAbbrev].push(newHistoryItem);
    }
}

// Helper to fetch SVG and return as Base64 Data URI
async function fetchSvgAsBase64(abbrev: string): Promise<string> {
    const url = `https://assets.nhle.com/logos/nhl/svg/${abbrev}_light.svg`;
    try {
        const response = await axios.get(url, { responseType: 'arraybuffer' });
        const base64 = Buffer.from(response.data, 'binary').toString('base64');
        return `data:image/svg+xml;base64,${base64}`;
    } catch (e) {
        console.error(`   ⚠️ Failed to fetch SVG for ${abbrev}, falling back to ESPN PNG.`);
        return getEspnLogoUrl(abbrev);
    }
}

function getEspnLogoUrl(abbrev: string): string {
    const code = abbrev.toUpperCase();
    const corrections: Record<string, string> = {
        'SJS': 'sj',
        'LAK': 'la',
        'TBL': 'tb',
        'NJD': 'nj',
        'UTA': 'utah',
        'VGK': 'vgs'
    };
    const cleanCode = corrections[code] || code.toLowerCase();
    return `https://a.espncdn.com/i/teamlogos/nhl/500/${cleanCode}.png`;
}

main();