import { aptos, getSigner } from "./aptos_utils";
import {
    Account,
    Aptos,
    AptosConfig,
    Ed25519PrivateKey,
    HexInput,
    Network,
    NetworkToNetworkName,
    InputViewFunctionData 
} from "@aptos-labs/ts-sdk";

const ACCOUNT = "0x0b1aeace2c12b282262fefc510704f2b37dca678fe7bdc3794628c5eaabc76dd";
const MODULE = "general_vault";

async function deposit() {
    const signer = await getSigner();
    const transaction = await aptos.transaction.build.simple(
        {
            sender: signer.accountAddress,
            data: {
                function: `${ACCOUNT}::${MODULE}::deposit_safety_vault`,
                functionArguments: ["0x1432adc04bde7645ce3ba9af2f7ecab30351d6c0fab0138b21377972a6261982", 1200000, 0, 0, false],
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
                functionArguments: [signer.accountAddress, 900_000, 2_000_000, 1, false],
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