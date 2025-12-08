import axios from 'axios';
import { NHLScheduleResponse, NHLStandingsResponse } from '../types';

const NHL_API_BASE = process.env.NHL_API_BASE || "https://api-web.nhle.com/v1";

export async function fetchStandings(): Promise<Record<string, { recordString: string, raw: any }>> {
    const url = `${NHL_API_BASE}/standings/now`;
    const response = await axios.get<NHLStandingsResponse>(url);

    const recordsMap: Record<string, { recordString: string, raw: any }> = {};

    for (const record of response.data.standings) {
        const abbrev = record.teamAbbrev.default;
        recordsMap[abbrev] = {
            recordString: `${record.wins}-${record.losses}-${record.otLosses}`,
            raw: record
        };
    }
    console.log(`   -> Fetched records for ${Object.keys(recordsMap).length} teams.`);
    return recordsMap;
}

export async function fetchSchedule(date: string): Promise<NHLScheduleResponse | null> {
    try {
        const url = `${NHL_API_BASE}/schedule/${date}`;
        const response = await axios.get<NHLScheduleResponse>(url);
        return response.data;
    } catch (error) {
        console.error(`Failed to fetch schedule for ${date}`);
        return null;
    }
}
