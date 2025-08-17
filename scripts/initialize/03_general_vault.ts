import { writeToEnvFile } from "../utils/helper";
import { aptos, getSigner } from "../utils/aptos_utils";
const { ACCOUNT } = require("../utils/constants");
const MODULE = "general_vault";
import {
    InputViewFunctionData 
} from "@aptos-labs/ts-sdk";

async function init_general_vault() {
    const signer = await getSigner();

    const transaction = await aptos.transaction.build.simple(
        {
            sender: signer.accountAddress,
            data: {
                function: `${ACCOUNT}::${MODULE}::init_vault`,
                functionArguments: [],
            }
        }
    )

    const committedTransaction = await aptos.signAndSubmitTransaction({ signer: signer, transaction });
    const executedTransaction = await aptos.waitForTransaction({ transactionHash: committedTransaction.hash });
    console.log(executedTransaction);

    const payload: InputViewFunctionData = {
        function: `${ACCOUNT}::${MODULE}::get_vault_address`,
        typeArguments: [],
        functionArguments: [],
    };
    const data = await aptos.view({payload});

    const vaultAddress = data[0];

    writeToEnvFile("VAULT_ADDRESS", vaultAddress.toString());
}

async function init_reward_pool() {
    const signer = await getSigner();

    const transaction = await aptos.transaction.build.simple(
        {
            sender: signer.accountAddress,
            data: {
                function: `${ACCOUNT}::${MODULE}::init_reward_pool`,
                functionArguments: [],
            }
        }
    )

    const committedTransaction = await aptos.signAndSubmitTransaction({ signer: signer, transaction });
    const executedTransaction = await aptos.waitForTransaction({ transactionHash: committedTransaction.hash });
    console.log(executedTransaction);

    const payload: InputViewFunctionData = {
        function: `${ACCOUNT}::${MODULE}::get_reward_pool_address`,
        typeArguments: [],
        functionArguments: [],
    };

    const data = await aptos.view({payload});

    const rewardPoolAddress = data[0];

    writeToEnvFile("REWARD_POOL", rewardPoolAddress.toString());
}

async function init_reserve_pool() {
    const signer = await getSigner();

    const transaction = await aptos.transaction.build.simple(
        {
            sender: signer.accountAddress,
            data: {
                function: `${ACCOUNT}::${MODULE}::init_reserve_pool`,
                functionArguments: [],
            }
        }
    )

    const committedTransaction = await aptos.signAndSubmitTransaction({ signer: signer, transaction });
    const executedTransaction = await aptos.waitForTransaction({ transactionHash: committedTransaction.hash });
    console.log(executedTransaction);

    const payload: InputViewFunctionData = {
        function: `${ACCOUNT}::${MODULE}::get_reserve_pool_address`,
        typeArguments: [],
        functionArguments: [],
    };

    const data = await aptos.view({payload});

    const reservePoolAddress = data[0];

    writeToEnvFile("RESERVE_POOL", reservePoolAddress.toString());
}


async function main() {
    await init_general_vault();
    await init_reward_pool();
    await init_reserve_pool();
}

main();