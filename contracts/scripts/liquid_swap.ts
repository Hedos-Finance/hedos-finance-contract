import { aptos, getSigner } from "./aptos_utils";

const ACCOUNT = "0b625e2c4582203073b54cded720782bd87b059ba98d8229177baf16b969c5d9";
const MODULE = "interact_liquid_swap";
const data = {
    "type_arguments":
        [
            "0x1::aptos_coin::AptosCoin",
            "0x9770fa9c725cbd97eb50b2be5f7416efdfd1f1554beb0750d4dae4c64e860da3::wrapped_coins::WrappedUSDC",
            "0x163df34fccbf003ce219d3f1d9e70d140b60622cb9dd47599c25fb2f797ba6e::curves::Uncorrelated",
            "0x9dd974aea0f927ead664b9e1c295e4215bd441a9fb4e53e5ea0bf22f356c8a2b::router::BinStepV0V05"
        ]
}

const data2 = {
    "type_arguments": [
        "0x9770fa9c725cbd97eb50b2be5f7416efdfd1f1554beb0750d4dae4c64e860da3::wrapped_coins::WrappedUSDC",
        "0x1::aptos_coin::AptosCoin",
        "0x163df34fccbf003ce219d3f1d9e70d140b60622cb9dd47599c25fb2f797ba6e::curves::Uncorrelated",
        "0x9dd974aea0f927ead664b9e1c295e4215bd441a9fb4e53e5ea0bf22f356c8a2b::router::BinStepV0V05"
    ]

}
async function liquid_swap_USDC_APT() {
    const signer = await getSigner();
    const transaction = await aptos.transaction.build.simple(
        {
            sender: signer.accountAddress,
            data: {
                function: `${ACCOUNT}::${MODULE}::liquid_swap_coin_for_exact_coin_x1`,
                typeArguments: data2.type_arguments,
                functionArguments: [100_000, [1_900_000], [0x05], [false]],
            }
        }
    )

    const committedTransaction = await aptos.signAndSubmitTransaction({ signer: signer, transaction });

    const executedTransaction = await aptos.waitForTransaction({ transactionHash: committedTransaction.hash });
    console.log(executedTransaction);
}

async function liquid_swap_APT_USDC() {
    const signer = await getSigner();
    const transaction = await aptos.transaction.build.simple(
        {
            sender: signer.accountAddress,
            data: {
                function: `${ACCOUNT}::${MODULE}::liquid_swap_coin_for_exact_coin_x1`,
                typeArguments: data.type_arguments,
                functionArguments: [2_042_858, [99_000], [0x05], [true]],
            }
        }
    )

    const committedTransaction = await aptos.signAndSubmitTransaction({ signer: signer, transaction });

    const executedTransaction = await aptos.waitForTransaction({ transactionHash: committedTransaction.hash });
    console.log(executedTransaction);
}

const USDC_COIN_TYPE = "0x9770fa9c725cbd97eb50b2be5f7416efdfd1f1554beb0750d4dae4c64e860da3::wrapped_coins::WrappedUSDC";

// Hàm gọi balance
async function getUsdcBalance(accountAddress: string) {
  try {
    const response = await aptos.getAccountCoinAmount({
      accountAddress,
      coinType: USDC_COIN_TYPE,
    });

    console.log("USDC balance:", response);
  } catch (err) {
    console.error("Failed to fetch balance:", err);
    return "0";
  }
}

async function main() {
    // await liquid_swap_USDC_APT();
    
}

main();