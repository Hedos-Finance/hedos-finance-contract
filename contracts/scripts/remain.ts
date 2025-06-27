import { aptos, getSigner } from "./aptos_utils";
import {
    Account,
    Aptos,
    AptosConfig,
    Ed25519PrivateKey,
    HexInput,
    Network,
    NetworkToNetworkName,
    ViewRequest
} from "@aptos-labs/ts-sdk";

const ACCOUNT = process.env.APTOS_ACCOUNT;
const MODULE = "general_vault";
// const admin = "0x0b625e2c4582203073b54cded720782bd87b059ba98d8229177baf16b969c5d9";
async function remain() {
    const signer = await getSigner();
    const transaction = await aptos.transaction.build.simple(
        {
            sender: signer.accountAddress,
            data: {
                function: `${ACCOUNT}::${MODULE}::swap_amAPT_remain`,
                functionArguments: [signer.accountAddress, 2_000_000],
            }
        }
    )

    const committedTransaction = await aptos.signAndSubmitTransaction({ signer: signer, transaction });

    const executedTransaction = await aptos.waitForTransaction({ transactionHash: committedTransaction.hash });
    console.log(executedTransaction);
}

async function withdraw() {
    const signer = await getSigner();
    const transaction = await aptos.transaction.build.simple(
        {
            sender: signer.accountAddress,
            data: {
                function: `${ACCOUNT}::${MODULE}::redeem_usdc`,
                functionArguments: [signer.accountAddress, 6_800_000],
            }
        }
    )

    const committedTransaction = await aptos.signAndSubmitTransaction({ signer: signer, transaction });

    const executedTransaction = await aptos.waitForTransaction({ transactionHash: committedTransaction.hash });
    console.log(executedTransaction);
}

async function main() {
    // await remain();
    await withdraw();
}

main();