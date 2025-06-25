import { ViewRequest } from "@aptos-labs/ts-sdk";
import { aptos, getSigner } from "./aptos_utils";

// const ACCOUNT = "0b625e2c4582203073b54cded720782bd87b059ba98d8229177baf16b969c5d9";
const ACCOUNT = process.env.APTOS_ACCOUNT;
const MODULE = "interact_cellana";

const data = {
    type_arguments: [
        "0x1::aptos_coin::AptosCoin"
    ]
}

const amount_in = 10_000; // 1_000_000 (1 APT nếu dùng 6 decimal)

const amount_out_min = 200_000; // slippage

const from_token = "0xbae207659db88bea0cbead6da0ed00aac12edcdda169e591cd41c94180b46f3b"; // Object<Metadata> resource address (hex string)
const to_tokens = ["0xedc2704f2cef417a06d1756a04a16a9fa6faaed13af469be9cdfcac5a21a8e2e"]; // vector<Object<Metadata>>
const is_stables = [false]; // vector<bool>

async function cellana_swap_USDC_APT() {
    const signer = await getSigner();
    const transaction = await aptos.transaction.build.simple(
        {
            sender: signer.accountAddress,
            data: {
                function: `${ACCOUNT}::${MODULE}::swap_route_entry_to_coin`,
                typeArguments: data.type_arguments,
                functionArguments: [10_000, 222_000, from_token, to_tokens, is_stables, signer.accountAddress]
            }
        }
    )

    const committedTransaction = await aptos.signAndSubmitTransaction({ signer: signer, transaction });

    const executedTransaction = await aptos.waitForTransaction({ transactionHash: committedTransaction.hash });
    console.log(executedTransaction);
}


async function cellana_swap_APT_USDC() {
    const signer = await getSigner();
    const transaction = await aptos.transaction.build.simple(
        {
            sender: signer.accountAddress,
            data: {
                function: `${ACCOUNT}::${MODULE}::swap_route_entry_to_coin`,
                typeArguments: data.type_arguments,
                functionArguments: [10_000, 222_000, from_token, to_tokens, is_stables, signer.accountAddress]
            }
        }
    )

    const committedTransaction = await aptos.signAndSubmitTransaction({ signer: signer, transaction });

    const executedTransaction = await aptos.waitForTransaction({ transactionHash: committedTransaction.hash });
    console.log(executedTransaction);
}

async function swap_USDC_APT() {
    const signer = await getSigner();
    const transaction = await aptos.transaction.build.simple(
        {
            sender: signer.accountAddress,
            data: {
                function: `${ACCOUNT}::${MODULE}::swap_USDC_to_APT`,
                functionArguments: [10_000]
            }
        }
    )

    const committedTransaction = await aptos.signAndSubmitTransaction({ signer: signer, transaction });

    const executedTransaction = await aptos.waitForTransaction({ transactionHash: committedTransaction.hash });
    console.log(executedTransaction);
}


async function swap_amAPT_USDC() {
    const signer = await getSigner();
    const transaction = await aptos.transaction.build.simple(
        {
            sender: signer.accountAddress,
            data: {
                function: `${ACCOUNT}::${MODULE}::swap_amAPT_to_USDC`,
                functionArguments: [100_000]
            }
        }
    )

    const committedTransaction = await aptos.signAndSubmitTransaction({ signer: signer, transaction });

    const executedTransaction = await aptos.waitForTransaction({ transactionHash: committedTransaction.hash });
    console.log(executedTransaction);
}
async function get_function() {
    const payload: ViewRequest = {
        function: `${ACCOUNT}::${MODULE}::get_amounts_out_APT_USDC_cellana`,
        typeArguments: [],
        functionArguments: [200_000_000],
    };
    const result = await aptos.view({ payload });

    console.log(`${result}`);
}

async function main() {
    // await get_function();
    // await swap_USDC_APT();
    // await cellana_swap_USDC_APT();
    await swap_amAPT_USDC();
}

main();