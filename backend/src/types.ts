// backend/src/types.ts

// --- 1. NHL API Interfaces ---
export interface NHLScheduleResponse {
  gameWeek: {
    date: string;
    games: NHLGameRaw[];
  }[];
}

export interface NHLGameRaw {
  id: number;
  startTimeUTC: string;
  gameState: string;
  // Add venue so we can read game.venue.default
  venue?: { default: string };
  tvBroadcasts?: Array<{ market: string; network: string }>;
  homeTeam: NHLTeamRaw;
  awayTeam: NHLTeamRaw;
}

export interface NHLTeamRaw {
  id: number;
  abbrev: string;
  placeName: { default: string };
  score?: number;
  logo: string;
}

export interface NHLStandingsResponse {
  standings: Array<{
    teamAbbrev: { default: string };
    wins: number;
    losses: number;
    otLosses: number;
  }>;
}

// --- 2. Firestore Interfaces ---

export interface FirestoreGame {
  gameId: string;
  startTime: string;
  status: string;
  // Add these fields so we can save them to Firestore
  venue: string;
  broadcasts: string;
  homeTeam: TeamSummary;
  awayTeam: TeamSummary;
  apiRaw?: any;
}

export interface TeamSummary {
  id: number;
  name: string;
  abbrev: string;
  score: number;
  logo: string;
  record: string;
}

export interface FirestoreTeam {
  teamId: string;
  name: string;
  record: string;
  logo: string;
  last5Games: Array<{
    gameId: string;
    opponent: string;
    date: string;
    score: string;
    outcome: string;
  }>;
}
