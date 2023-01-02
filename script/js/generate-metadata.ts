import "dotenv/config";
import { writeFile } from "fs/promises";
import { parseCsvToJson } from "./parse-csv";

type Metadata = {
    name: string;
    description: string;
    image: string;
    attributes: {
        trait_type: string;
        value: string;
    }[];
};

const applyAdditionalMetadata = (
    collection: string,
    song: string,
    attributes: { trait_type: string; value: string }[],
    songData: { [key: string]: any }
): { trait_type: string; value: string }[] => {
    const attributeList = ["Artist", "Genre", "BPM", "Duration"];
    attributeList.forEach((attr) =>
        attributes.push({
            trait_type: attr,
            value: songData[collection][song][attr],
        })
    );
    return attributes;
};

const generateMetadataForSong = (
    _collection: string,
    _song: string,
    _attributesList: { trait_type: string; value: string }[],
    _songs: { [key: string]: any }
) => {
    let tempMetadata = {
        name: _songs[_collection][_song]["Song"],
        description: _songs[_collection][_song]["Description"],
        animation_url: encodeURI(_songs[_collection][_song]["Animation"]),
        image: encodeURI(_songs[_collection][_song]["Image"]),
        attributes: _attributesList,
        artist: _songs[_collection][_song]["Artist"],
        genre: _songs[_collection][_song]["Genre"],
        trackNumber: _songs[_collection][_song]["SongId"],
        originalReleaseDate: _songs[_collection][_song]["Release Date"],
    };
    return tempMetadata;
};

/**
 * Builds an interfaceIds.js file so we can publish the ids as string constants.
 */
async function generateMetadata() {
    const metadataInput = await parseCsvToJson(`src/csv/Drop - Metadata Final.csv`);
    const folderPath = `src/metadata/`;

    let metadataList: Metadata[] = [];
    // const tlKeys = Object.keys(metadataInput);
    // console.log({ tlKeys });
    // for (let i = 0; i < tlKeys.length; i++) {
        const collectionId = '1'
        const llKeys = Object.keys(metadataInput[collectionId]);
        console.log({ llKeys });
        for (let j = 0; j < llKeys.length; j++) {
            const songId = llKeys[j];
            console.log("-----------------");
            console.log("creating NFT metadata for collection %d song %d", collectionId, songId);

            let attributesList: { trait_type: string; value: string }[] = [];
            attributesList = applyAdditionalMetadata(collectionId, songId, attributesList, metadataInput);
            let nftMetadata = generateMetadataForSong(collectionId, songId, attributesList, metadataInput);
            writeFile(
                folderPath + collectionId.toString() + "/" + songId.toString(),
                // folderPath + collectionId.toString() + "/" + songId.toString() + ".json",
                JSON.stringify(nftMetadata)
            );
            metadataList.push(nftMetadata);
            console.log("- metadata: " + JSON.stringify(nftMetadata));
            console.log();
        }
    // }

    await writeFile(folderPath + "test.json", JSON.stringify(metadataInput));
}

await generateMetadata();
