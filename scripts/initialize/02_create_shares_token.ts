import { aptos, getSigner } from "../utils/aptos_utils";
import { writeToEnvFile } from "../utils/helper";
import {
    InputViewFunctionData 
} from "@aptos-labs/ts-sdk";
const { ACCOUNT } = require("../utils/constants");
const MODULE = "shares_token";

async function create_safety() {
    const signer = await getSigner();

    const transaction = await aptos.transaction.build.simple(
        {
            sender: signer.accountAddress,
            data: {
                function: `${ACCOUNT}::${MODULE}::create_token`,
                functionArguments: ["Safety", "SHT", ".", "https://hedos.finance"],
            }
        }
    )

    const committedTransaction = await aptos.signAndSubmitTransaction({ signer: signer, transaction });
    const executedTransaction = await aptos.waitForTransaction({ transactionHash: committedTransaction.hash });
    console.log(executedTransaction);
}

async function create_risky() {
    const signer = await getSigner();

    const transaction = await aptos.transaction.build.simple(
        {
            sender: signer.accountAddress,
            data: {
                function: `${ACCOUNT}::${MODULE}::create_token`,
                functionArguments: ["Risky", "RHT", ".", "https://hedos.finance"],
            }
        }
    )

    const committedTransaction = await aptos.signAndSubmitTransaction({ signer: signer, transaction });
    const executedTransaction = await aptos.waitForTransaction({ transactionHash: committedTransaction.hash });
    console.log(executedTransaction);
}

async function writeData() {
    const payload: InputViewFunctionData  = {
        function: `${ACCOUNT}::${MODULE}::get_shares_token_address`,
        typeArguments: [],
        functionArguments: [
        ],
    };
    const data = await aptos.view({payload});

    const SAFETY = data[0];
    const RISKY = data[1];

    writeToEnvFile("SAFETY", SAFETY.toString());
    writeToEnvFile("RISKY", RISKY.toString());
}

async function create_shares_token() {
    await create_safety();
    await create_risky();
    await writeData();
}

async function main() {
    await create_shares_token();
}

main();