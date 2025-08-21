import { Aptos } from "@aptos-labs/ts-sdk";
import { MerkleClient, MerkleClientConfig } from "@merkletrade/ts-sdk";

async function main() {
    const merkle = new MerkleClient(await MerkleClientConfig.mainnet());
    const aptos = new Aptos(merkle.config.aptosConfig);

    const session = await merkle.getPositions({address: "0x0e69a8c2ee20552b88a9e7d9be52177ec168ededd6b5720f9c5b57ce825756c0"})
    console.log(session);
}

main();