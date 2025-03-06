import { StandardMerkleTree } from "@openzeppelin/merkle-tree";
import fs from "fs";


const tree = StandardMerkleTree.load(JSON.parse(fs.readFileSync('exampleTree.json', 'utf8')));


const proof = tree.getProof(0);

console.log('Proof for 0: ', proof);

const proof2 = tree.getProof(1);

console.log('Proof for 1: ', proof2);

console.log("Root ", tree.root)