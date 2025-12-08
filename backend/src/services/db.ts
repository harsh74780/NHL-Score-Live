import * as admin from 'firebase-admin';
import * as path from 'path';
import * as fs from 'fs';
import { FirestoreGame, FirestoreTeam } from '../types';

let db: admin.firestore.Firestore;

export function initFirestore() {
    if (admin.apps.length > 0) {
        db = admin.firestore();
        return db;
    }

    const serviceAccountPath = process.env.GOOGLE_APPLICATION_CREDENTIALS
        ? path.resolve(process.env.GOOGLE_APPLICATION_CREDENTIALS)
        : path.resolve(__dirname, '../../serviceAccountKey.json'); // Adjusted path for nested folder

    console.log(`DEBUG: Attempting to load service account from: ${serviceAccountPath}`);
    try {
        const serviceAccount = JSON.parse(fs.readFileSync(serviceAccountPath, 'utf8'));
        admin.initializeApp({
            credential: admin.credential.cert(serviceAccount)
        });
        db = admin.firestore();
        db.settings({ ignoreUndefinedProperties: true });
        console.log("🔥 Firestore initialized.");
    } catch (error) {
        console.error(`ERROR: Failed to load service account! Path: ${serviceAccountPath}`);
        console.error(`Details: ${(error as Error).message}`);
        process.exit(1);
    }
    return db;
}

export function getDb() {
    if (!db) return initFirestore();
    return db;
}

export async function batchSaveGames(games: FirestoreGame[]) {
    if (games.length === 0) return;
    const batch = getDb().batch();

    games.forEach(game => {
        const gameRef = getDb().collection('games').doc(game.gameId);
        batch.set(gameRef, game, { merge: true });
    });

    await batch.commit();
}

export async function batchSaveTeams(teams: FirestoreTeam[]) {
    if (teams.length === 0) return;
    const batch = getDb().batch();

    teams.forEach(team => {
        const teamRef = getDb().collection('teams').doc(team.teamId);
        batch.set(teamRef, team, { merge: true });
    });

    await batch.commit();
}
