import { Account, 
    Aptos, 
    AptosConfig, 
    Network, 
    Ed25519PrivateKey, 
    PrivateKey, 
    PrivateKeyVariants,
    AccountAddress,
    InputViewFunctionData 
   } from "@aptos-labs/ts-sdk";

const APTOS_COIN = "0x1::aptos_coin::AptosCoin";
const COIN_STORE = `0x1::coin::CoinStore<${APTOS_COIN}>`;


const profile_addr= "0xcb6060b12c954f3b580b1533d014590507643469bbb212c50dfbdf7bac1c69a9"

// Setup the client
const config = new AptosConfig({ network: Network.DEVNET });
const aptos = new Aptos(config);

function stringToHex(str: string): Uint8Array {
    return new TextEncoder().encode(str);
}

const create_action_list = async function(account: Account){

    const txn = await aptos.transaction.build.simple({
        sender: account.accountAddress,
        data: {
        // All transactions on Aptos are implemented via smart contracts.
        function: `${profile_addr}::profile::create_action_list`,
        functionArguments: [],
        },
    });
    
    console.log("\n=== Transfer transaction ===\n");
    // Both signs and submits
    const committedTxn = await aptos.signAndSubmitTransaction({
        signer: account,
        transaction: txn,
    });
    // Waits for Aptos to verify and execute the transaction
    const executedTransaction = await aptos.waitForTransaction({
        transactionHash: committedTxn.hash,
    });
    console.log("Transaction hash:", executedTransaction.hash);
    return executedTransaction.hash
  }

  const action = async function(action_list_idx: number, act: number, message: string, account: Account){

    const txn = await aptos.transaction.build.simple({
        sender: account.accountAddress,
        data: {
        // All transactions on Aptos are implemented via smart contracts.
        function: `${profile_addr}::profile::action`,
        functionArguments: [action_list_idx, act, message],
        },
    });
    
    console.log("\n=== Transfer transaction ===\n");
    // Both signs and submits
    const committedTxn = await aptos.signAndSubmitTransaction({
        signer: account,
        transaction: txn,
    });
    // Waits for Aptos to verify and execute the transaction
    const executedTransaction = await aptos.waitForTransaction({
        transactionHash: committedTxn.hash,
    });
    console.log("Transaction hash:", executedTransaction.hash);
    return executedTransaction.hash
  }

  const get_actionList_counter = async function(addr : AccountAddress){

    const payload: InputViewFunctionData = {
        function:  `${profile_addr}::profile::get_action_list_counter`,
        functionArguments: [addr],
      };
    try {  
        const ret = (await aptos.view({ payload }));
        console.log("get_actionList_counter: ", ret)
        return ret
    } catch (e) {
        console.log("Error in get_actionList_counter :", e)
        console.log("Error in get_actionList_counter :", e.data.error_code)
        // const properties = Object.getOwnPropertyNames(e);
        // for (const prop of properties) {
        //     console.log(`${prop}:`, e[prop as keyof Error]);
        // }
    }
    
  }

  const get_action_list = async function(addr : AccountAddress, action_list_idx: number){

    const payload: InputViewFunctionData = {
        function:  `${profile_addr}::profile::get_action_list`,
        functionArguments: [addr, action_list_idx],
      };
    try {  
        const ret = (await aptos.view({ payload }));
        console.log("get_action_list: ", ret)
        return ret
    } catch (e) {
        console.log("Error in get_action_list :", e)
        console.log("Error in get_action_list :", e.data.error_code)
        // const properties = Object.getOwnPropertyNames(e);
        // for (const prop of properties) {
        //     console.log(`${prop}:`, e[prop as keyof Error]);
        // }
    }
    
  }

  const get_action = async function(addr : AccountAddress, action_list_idx: number, action_idx: number){

    const payload: InputViewFunctionData = {
        function:  `${profile_addr}::profile::get_action`,
        functionArguments: [addr, action_list_idx, action_idx],
      };
    try {  
        const ret = (await aptos.view({ payload }));
        console.log("get_action: ", ret)
        return ret
    } catch (e) {
        console.log("Error in get_action :", e)
        console.log("Error in get_action :", e.data.error_code)
        // const properties = Object.getOwnPropertyNames(e);
        // for (const prop of properties) {
        //     console.log(`${prop}:`, e[prop as keyof Error]);
        // }
    }
    
  }


  async function balanceOfAccount(addr: AccountAddress) {
      try {
          const AccountBalance = await aptos.getAccountResource({
              accountAddress: addr,
              resourceType: COIN_STORE,
          });
          const Balance = Number(AccountBalance.coin.value);
          console.log(`${addr}'s balance is: ${Balance}`);
  
          return Balance;
      } catch (e) {
          console.log("Error in getAccountResource :", e)
          console.log("Error in getAccountResource :", e.data.error_code)
          // const properties = Object.getOwnPropertyNames(e);
          // for (const prop of properties) {
          //     console.log(`${prop}:`, e[prop as keyof Error]);
          // }
          console.log(`${addr}'s balance is: 0`);
          return 0;
      }
  }

  async function fundAccount(addr: AccountAddress, amount: number) {
      await aptos.fundAccount({
          accountAddress: addr,
          amount: amount,
        });
  }

async function example() {
    console.log(
        "This example is helloapt",
    );
    const alice_prviatekey = 'ed25519-priv-0x9b94923677cb9fedc19df8dcf13f4f336a1849431166a7bfb2f47fbada3b9c4e'
    const bob_prviatekey = 'ed25519-priv-0x5f9ed5ffd67e697d3f1052627d4cf427f35edd3f23557e1f709088ea0dc278aa'


    const alice = Account.fromPrivateKey({privateKey: new Ed25519PrivateKey(alice_prviatekey)})
    const bob = Account.fromPrivateKey({privateKey: new Ed25519PrivateKey(bob_prviatekey)})
    console.log(`Alice's address is: ${alice.accountAddress}`);
    console.log(`Bob's address is: ${bob.accountAddress}`);

    
    // await create_action_list(alice)

    // await action(0, 1, "download xworld APP", alice)

    // await get_actionList_counter(alice.accountAddress)

    // await get_action_list(alice.accountAddress, 0)

    await get_action(alice.accountAddress, 0, 0)
}

example();