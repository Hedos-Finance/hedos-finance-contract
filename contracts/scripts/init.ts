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

async function init() {
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
}

async function init_fund_fee() {
    const signer = await getSigner();
    const transaction = await aptos.transaction.build.simple(
        {
            sender: signer.accountAddress,
            data: {
                function: `${ACCOUNT}::${MODULE}::set_fund_fee_risky_rate`,
                functionArguments: [3,10],
            }
        }
    )

    const committedTransaction = await aptos.signAndSubmitTransaction({ signer: signer, transaction });

    const executedTransaction = await aptos.waitForTransaction({ transactionHash: committedTransaction.hash });
    console.log(executedTransaction);
}
async function get_function() {
    let payload: ViewRequest;
    payload = {
        function: `${ACCOUNT}::${MODULE}::get_vault_address`,
        typeArguments: [],
        functionArguments: [],
    };
    let result = await aptos.view({ payload });

    console.log("address vault", `${result}`);

    payload = {
        function: `${ACCOUNT}::${MODULE}::get_total_value_lock`,
        typeArguments: [],
        functionArguments: [],
    };
    result = await aptos.view({ payload });

    console.log("TVL vault", `${result}`);

    payload = {
        function: `${ACCOUNT}::${MODULE}::get_total_staked`,
        typeArguments: [],
        functionArguments: [],
    };
    result = await aptos.view({ payload });

    console.log("staked vault", `${result}`);

        payload = {
        function: `${ACCOUNT}::${MODULE}::get_total_perpeptual`,
        typeArguments: [],
        functionArguments: [],
    };
    result = await aptos.view({ payload });

    console.log("perp vault", `${result}`);

}

async function get_function_fund_fee() {
    let payload: ViewRequest;
    payload = {
        function: `${ACCOUNT}::${MODULE}::fund_fee_ratio`,
        typeArguments: [],
        functionArguments: [],
    };
    let result = await aptos.view({ payload });

    console.log("result", `${result}`);

}
async function main() {
    // await init();
    // await init_fund_fee();
    await get_function_fund_fee();
    // await get_function();
}

main();