import { StandardMerkleTree } from "@openzeppelin/merkle-tree";
import fs from "fs";

const values = JSON.parse(fs.readFileSync("utils/distribution.json"))

const tree = StandardMerkleTree.of(values, ["address", "uint256"]);

console.log('Merkle Root:', tree.root);

fs.writeFileSync("tree.json", JSON.stringify(tree.dump()));