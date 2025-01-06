import { StandardMerkleTree } from "@openzeppelin/merkle-tree";
import fs from "fs";


function main() {

    const tree = StandardMerkleTree.load(JSON.parse(fs.readFileSync('test/utils/testTree.json', 'utf8')));

    const [leafIndex] = process.argv.slice(2);

    const value = Number(leafIndex);
    const leaf = tree.at(value);
    console.log("0x" +  leaf[0].substring(2).padStart(64, "0") +  Number(leaf[1]).toString(16).padStart(64, "0"));
}

main();

