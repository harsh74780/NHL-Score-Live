export function sleep(ms: number) {
    return new Promise(resolve => setTimeout(resolve, ms));
}

export function mapGameStatus(apiStatus: string): string {
    if (apiStatus === "OFF" || apiStatus === "FINAL") return "Final";
    if (apiStatus === "LIVE" || apiStatus === "CRIT") return "Live";
    return "Scheduled";
}
