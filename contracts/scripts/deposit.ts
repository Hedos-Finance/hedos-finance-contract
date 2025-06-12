import { aptos, getSigner } from "./aptos_utils";

const ACCOUNT = "0b625e2c4582203073b54cded720782bd87b059ba98d8229177baf16b969c5d9";
const MODULE = "vault";

async function deposit() {
    const signer = await getSigner();
    const transaction = await aptos.transaction.build.simple(
        {
            sender: signer.accountAddress,
            data: {
                function: `${ACCOUNT}::${MODULE}::deposit`,
                functionArguments: [10_000],
            }
        }
    )

    const committedTransaction = await aptos.signAndSubmitTransaction({ signer: signer, transaction });

    const executedTransaction = await aptos.waitForTransaction({ transactionHash: committedTransaction.hash });
    console.log(executedTransaction);
}

async function init() {
   const signer = await getSigner();
    const transaction = await aptos.transaction.build.simple(
        {
            sender: signer.accountAddress,
            data: {
                function: `${ACCOUNT}::${MODULE}::initialize_vault`,
                functionArguments: [],
            }
        }
    )

    const committedTransaction = await aptos.signAndSubmitTransaction({ signer: signer, transaction });

    const executedTransaction = await aptos.waitForTransaction({ transactionHash: committedTransaction.hash });
    console.log(executedTransaction);
}

async function checkBalance() {
    const signer = await getSigner();
    const accountAddress = "0x70e9853c05beac263a6fee5dd46989540dc59694ec84456c79f1751da803e102";
    const usdcType = "0xb625e2c4582203073b54cded720782bd87b059ba98d8229177baf16b969c5d9::vault::USDC";
    // const resources = await aptos.getAccountResources({ accountAddress: accountAddress });
    // const usdcResource = resources.find(
    //   (r) => r.type === `0x1::coin::CoinStore<${usdcType}>`
    // );
    // const balance = usdcResource ? (usdcResource.data as any).coin.value : 0;
    // console.log(`USDC balance: ${balance} microUSDC`);
    // return balance;

    // const resources = await aptos.getAccountResources({ accountAddress });
    // const coinStores = resources.filter((r) => r.type.startsWith("0x1::coin::CoinStore"));
    // for (const store of coinStores) {
    // const balance = (store.data as any).coin.value;
    // console.log(`Coin type: ${store.type}, Balance: ${balance}`);
    // }
}


async function main() {
    await checkBalance();
    // await deposit();
    // await init();

}

main();