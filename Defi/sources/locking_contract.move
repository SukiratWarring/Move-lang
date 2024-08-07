// module myAddress::LockContract{
//     use std::signer;
//     use std::debug::print;
//     use std::vector;
//     use aptos_std::table::{Self,Table};
//     use std::error;
//     use std::timestamp;
//     use aptos_framework::coin;
//     use aptos_framework::aptos_coin::AptosCoin;
//     use std::string;
//     use aptos_framework::account;

//     const E_NOT_INITIALISED:u64=0;
//     struct LockDetails has store,copy,drop{
//         coins: u64,
//         unlock_time_sec:u64
//     }
    
//     struct Address_to_lock<phantom CoinType> has key {
//         all_locks:Table<address, vector<LockDetails>>,
//     }

//     public entry fun init<CoinType>(account:&signer){
//         let addr=signer::address_of(account);
//         let t=table::new<address, vector<LockDetails>>();
//         move_to(account,Address_to_lock<CoinType>{
//             all_locks: t,
//         })

//     }

//     public entry fun lock<CoinType>(account:&signer,unlock_time:u64,amt:u64) acquires Address_to_lock{
//         let lock_addr=signer::address_of(account);
//         assert!(exists<Address_to_lock<CoinType>>(lock_addr),error::internal(E_NOT_INITIALISED));
//         let address_to_lock =  borrow_global_mut<Address_to_lock<CoinType>>(lock_addr);
//         let vec = if (table::contains(&address_to_lock.all_locks, lock_addr)) {
//             table::borrow_mut(&mut address_to_lock.all_locks, lock_addr)
//         } else {
//             let v = vector::empty<LockDetails>();
//             table::add(&mut address_to_lock.all_locks, lock_addr, v);
//             table::borrow_mut(&mut address_to_lock.all_locks, lock_addr)
//         };
//         vector::push_back(vec, LockDetails{
//             coins:amt,
//             unlock_time_sec:unlock_time,
//         });
//     }

//     public fun calcualte_rewards<CoinType>(account:&signer):u64 acquires Address_to_lock{
//         //get all locks
//         let address_to_check =  borrow_global_mut<Address_to_lock<CoinType>>(signer::address_of(account));
//         let all_locks=table::borrow_mut(&mut address_to_check.all_locks, signer::address_of(account));
//         let total_rewards=0;
//         vector::for_each_mut<LockDetails>(all_locks,|each_lock|{
//             let lock:&mut LockDetails=each_lock;
//             if(timestamp::now_seconds()>=lock.unlock_time_sec){
//             let diffTime=timestamp::now_seconds()-lock.unlock_time_sec;
//             let reward=lock.coins * diffTime;
//             total_rewards=reward+total_rewards;
//             //print<LockDetails>(lock);
//             } 
//         });
//         total_rewards

//     }

//     public fun batchLock<CoinType>(account:&signer,batchLocks:vector<LockDetails>) acquires Address_to_lock{
//         let lock_addr=signer::address_of(account);
//         assert!(exists<Address_to_lock<CoinType>>(lock_addr),error::internal(E_NOT_INITIALISED));
//         //Get the vector
//         let access_storage=borrow_global_mut<Address_to_lock<CoinType>>(lock_addr);
//         let allLocks=table::borrow_mut(&mut access_storage.all_locks,lock_addr);
//         //Add the locks
//         vector::append(allLocks,batchLocks);

//         //print<vector<LockDetails>>(allLocks);
//     }

//     public fun distributeFunds<CoinType>(account:&signer)acquires Address_to_lock{
//         let addr=signer::address_of(account);
//         let rewards=calcualte_rewards<CoinType>(account);
//         // //print(rewards);
//         coin::transfer<CoinType>(account,addr, rewards);
//     }

//     public fun getAllLocks<CoinType>(account:&signer):vector<LockDetails> acquires Address_to_lock{
//         let address_to_check =  borrow_global<Address_to_lock<CoinType>>(signer::address_of(account));
//         *table::borrow(&address_to_check.all_locks, signer::address_of(account))

//     }

//     #[test_only]
//     fun setup_enviroment(test_acc:&signer){
//         timestamp::set_time_has_started_for_testing(test_acc);
//         account::create_account_for_test(signer::address_of(test_acc));
//         init<AptosCoin>(test_acc);
//         let (burn_cap, freeze_cap, mint_cap) = coin::initialize<AptosCoin>(
//             test_acc,
//             string::utf8(b"TestCoin"),
//             string::utf8(b"TC"),
//             8,
//             false,
//         );
//         coin::register<AptosCoin>(test_acc);
//         let coins =coin::mint<AptosCoin>(20000,&mint_cap);
//         coin::deposit(signer::address_of(test_acc), coins);
//         coin::destroy_mint_cap(mint_cap);
//         coin::destroy_freeze_cap(freeze_cap);        
//         coin::destroy_burn_cap(burn_cap);        
//     }
    
//     #[test(test_acc=@aptos_framework)]
//     public entry fun create_lock(test_acc:&signer)acquires Address_to_lock{
//         setup_enviroment(test_acc);
//         lock<AptosCoin>(test_acc,20000,20000);
//         timestamp::fast_forward_seconds(30000);
//         //check the lock
//         let check_all_locks=getAllLocks<AptosCoin>(test_acc);
//         assert!(vector::length(&check_all_locks)==1,0);
//         let total_rewards=calcualte_rewards<AptosCoin>(test_acc);
//         // //print(&total_rewards);
//     }

//     #[test(test_acc=@aptos_framework)]
//     public entry fun test_batch(test_acc:&signer) acquires Address_to_lock{
//         setup_enviroment(test_acc);
//         lock<AptosCoin>(test_acc,20000,20000);
//         timestamp::fast_forward_seconds(30000);
//         //Create the batch locally for test
//         let batch=vector::empty<LockDetails>();
//         vector::push_back(&mut batch,LockDetails{coins:23,unlock_time_sec:2000});
//         vector::push_back(&mut batch,LockDetails{coins:66,unlock_time_sec:43545});
//         // //print<vector<LockDetails>>(&batch);
//         batchLock<AptosCoin>(test_acc,batch);
//         //Check the lock
//         let check_all_locks=getAllLocks<AptosCoin>(test_acc);
//         assert!(vector::length(&check_all_locks)==3,0);

//     }

// }