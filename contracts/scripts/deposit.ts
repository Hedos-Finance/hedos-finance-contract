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

async function deposit() {
    const signer = await getSigner();
    const transaction = await aptos.transaction.build.simple(
        {
            sender: signer.accountAddress,
            data: {
                function: `${ACCOUNT}::${MODULE}::deposit_safety_vault`,
                functionArguments: [signer.accountAddress, 2_100_000, 6_808_405, 0, false],
            }
        }
    )

    const committedTransaction = await aptos.signAndSubmitTransaction({ signer: signer, transaction });

    const executedTransaction = await aptos.waitForTransaction({ transactionHash: committedTransaction.hash });
    console.log(executedTransaction);
}

async function deposit2() {
    const signer = await getSigner();
    const transaction = await aptos.transaction.build.simple(
        {
            sender: signer.accountAddress,
            data: {
                function: `${ACCOUNT}::${MODULE}::deposit_safety_vault`,
                functionArguments: [signer.accountAddress, 2_000_000, 2_000_000, 1, false],
            }
        }
    )

    const committedTransaction = await aptos.signAndSubmitTransaction({ signer: signer, transaction });

    const executedTransaction = await aptos.waitForTransaction({ transactionHash: committedTransaction.hash });
    console.log(executedTransaction);
}

async function main() {
    // await init();
    await deposit();
}

main();