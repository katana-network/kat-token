import { StandardMerkleTree } from "@openzeppelin/merkle-tree";
import fs from "fs";


function main() {

    const tree = StandardMerkleTree.load(JSON.parse(fs.readFileSync('test/utils/testTree.json', 'utf8')));

    const [leafIndex] = process.argv.slice(2);

    const value = Number(leafIndex);
    const proof = tree.getProof(value);
    let length = proof.length;
    const encoded = ["0x" + ((2).toString(16) + "0").padStart(64, "0"), "0x" + length.toString(16).padStart(64, "0")];
    const total = encoded.concat(proof)
    console.log("0x" + total.map(x => x.substring(2)).join(""));
}

main();
