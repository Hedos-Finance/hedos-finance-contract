import { aptos, getSigner } from "./aptos_utils";

const ACCOUNT = "0b625e2c4582203073b54cded720782bd87b059ba98d8229177baf16b969c5d9";
const MODULE = "swap";
const AMPT = "0x111ae3e5bc816a5e63c2da97d0aa3886519e0cd5e4b046659fa35796bd11542a::amapt_token::AmnisApt";
const APT = "0x1::aptos_coin::AptosCoin";
const data =
{
    "type_arguments": [
        "0x111ae3e5bc816a5e63c2da97d0aa3886519e0cd5e4b046659fa35796bd11542a::amapt_token::AmnisApt",
        "0x1::aptos_coin::AptosCoin"
    ]
}

async function swap() {
    const signer = await getSigner();
    const transaction = await aptos.transaction.build.simple(
        {
            sender: signer.accountAddress,
            data: {
                function: `${ACCOUNT}::${MODULE}::swap`,
                typeArguments: data.type_arguments,
                functionArguments: [25_438_769, 25_000_000],
            }
        }
    )

    const committedTransaction = await aptos.signAndSubmitTransaction({ signer: signer, transaction });

    const executedTransaction = await aptos.waitForTransaction({ transactionHash: committedTransaction.hash });
    console.log(executedTransaction);
}

async function main() {
    await swap();
}



main();