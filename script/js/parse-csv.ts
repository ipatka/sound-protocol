import * as csv from "@fast-csv/parse";
import * as fs from 'fs';


export const parseCsvToJson = async (inputCsv: string) => {
        const dataMap: { [key: string]: any } = {};
        const myPromise = new Promise((resolve, reject) => {
            fs.createReadStream(inputCsv)
                .pipe(csv.parse({ headers: true }))
                .on("error", (error: any) => console.error(error))
                .on("data", (row: { [key: string]: string }) => {
                    // console.log({row, act: row.ActID, scene: row.SceneId})
                    if (dataMap[row["Collection"]]) {
                        console.log(`Setting existing ${row["Collection"]}`);
                        dataMap[row["Collection"]][row["SongId"]] = row;
                    } else {
                        console.log(`Setting new ${row["Collection"]}`);
                        dataMap[row["Collection"]] = {
                            [row["SongId"]]: row,
                        };
                    }
                })
                .on("end", (rowCount: any) => {
                    console.log(`Parsed ${rowCount} rows`);
                    resolve("done");
                });
        });

        await myPromise;
        return dataMap


}
