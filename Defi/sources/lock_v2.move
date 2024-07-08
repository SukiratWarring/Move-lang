module myAddress::Lock_V2{
    use std::signer;
    use std::debug::print;
    use std::vector;
    use aptos_std::table::{Self,Table};
    use std::error;
    use std::timestamp;
    use aptos_framework::coin;
    use aptos_framework::aptos_coin::AptosCoin;
    use std::string;
    use aptos_framework::account;

    const E_NOT_INITIALISED:u64=0;
    struct LockDetails has store,copy,drop{
        coins: u64,
        unlock_time_sec:u64
    }
    
    #[test_only]
    struct Warin has key{}
    struct Lock_resource<phantom CoinType> has key{
        all_locks:Table<address, vector<LockDetails>>,
        resource_signer_cap: account::SignerCapability,
    }

    public entry fun init<CoinType>(source: &signer, seed: vector<u8>,){
        let t=table::new<address, vector<LockDetails>>();
        //Creating Resource_Account
         let (resource_signer, resource_signer_cap) = account::create_resource_account(source, seed);
         move_to(
            source,
            Lock_resource<CoinType>{
                all_locks: t,
                resource_signer_cap,
            }
         )

    }

    public entry fun lock<CoinType>(account:&signer,unlock_time:u64,amt:u64,source:address) acquires Lock_resource{
        let lock_addr=signer::address_of(account);
        assert!(exists<Lock_resource<CoinType>>(source),error::internal(E_NOT_INITIALISED));
        let lock_res =  borrow_global_mut<Lock_resource<CoinType>>(source);
        let vec = if (table::contains(&lock_res.all_locks, lock_addr)) {
            table::borrow_mut(&mut lock_res.all_locks, lock_addr)
        } else {
            let v = vector::empty<LockDetails>();
            table::add(&mut lock_res.all_locks, lock_addr, v);
            table::borrow_mut(&mut lock_res.all_locks, lock_addr)
        };
        vector::push_back(vec, LockDetails{
            coins:amt,
            unlock_time_sec:unlock_time,
        });
        coin::transfer<CoinType>(account,source,amt);

    }

    fun update_rewards<CoinType>(account:&signer,source:address):(u64, u64) acquires Lock_resource{
        //get all locks
        let lock_res =  borrow_global_mut<Lock_resource<CoinType>>(source);
        let all_locks=table::borrow_mut(&mut lock_res.all_locks, signer::address_of(account));
        let total_rewards=0;
        let total_unLocks_staked_token=0;
        vector::for_each_mut<LockDetails>(all_locks,|each_lock|{
            let lock:&mut LockDetails=each_lock;
            if(timestamp::now_seconds()>=lock.unlock_time_sec){
            total_unLocks_staked_token=total_unLocks_staked_token+lock.coins;
            let diffTime=timestamp::now_seconds()-lock.unlock_time_sec;
            let reward=lock.coins * diffTime;
            total_rewards=reward+total_rewards;
            } 
        });
        (total_rewards,total_unLocks_staked_token)

    }

    public fun batchLock<CoinType>(account:&signer,batchLocks:vector<LockDetails>,source:address) acquires Lock_resource{
        let lock_addr=signer::address_of(account);
        assert!(exists<Lock_resource<CoinType>>(source),error::internal(E_NOT_INITIALISED));
        //Get the vector
        let access_storage=borrow_global_mut<Lock_resource<CoinType>>(source);
        let allLocks=table::borrow_mut(&mut access_storage.all_locks,lock_addr);
        //Add the locks
        vector::append(allLocks,batchLocks);
        //Transfer the coins
        let sum=0;
        vector::for_each<LockDetails>(batchLocks,|each_lock|{
            let lock:LockDetails=each_lock;
            sum=sum+lock.coins;
        }
        );
        coin::transfer<CoinType>(account,source,sum);
    }

    public fun distributeFunds<CoinType,RewardType>(source_acc:&signer,to:&signer)acquires Lock_resource{
        // let staked_amt=
        let (rewards,unlock_staked)=update_rewards<CoinType>(to,signer::address_of(source_acc));
        print(&rewards);
        coin::transfer<CoinType>(source_acc,signer::address_of(to),unlock_staked);
        //Transfer Reward Token
        coin::transfer<RewardType>(source_acc,signer::address_of(to),rewards);
    }

    public fun getAllLocks<CoinType>(account:&signer,source:address):vector<LockDetails> acquires Lock_resource{
        let address_to_check =  borrow_global<Lock_resource<CoinType>>(source);
        *table::borrow(&address_to_check.all_locks, signer::address_of(account))
    }

    #[test_only]
    fun setup_enviroment(test_acc:&signer,source_acc:&signer){
        timestamp::set_time_has_started_for_testing(test_acc);
        account::create_account_for_test(signer::address_of(test_acc));
        account::create_account_for_test(signer::address_of(source_acc));
        let seed = x"01";        

        let (burn_cap, freeze_cap, mint_cap) = coin::initialize<AptosCoin>(
            test_acc,//0x1
            string::utf8(b"TestCoin"),
            string::utf8(b"TC"),
            8,
            false,
        );
        coin::register<AptosCoin>(test_acc);
        coin::register<AptosCoin>(source_acc);
        let coins =coin::mint<AptosCoin>(20000000,&mint_cap);
        init<AptosCoin>(source_acc,seed);

        coin::deposit(signer::address_of(test_acc), coins);
        coin::destroy_mint_cap(mint_cap);
        coin::destroy_freeze_cap(freeze_cap);        
        coin::destroy_burn_cap(burn_cap);    

        //Reward Coin
        let (burn_cap_1, freeze_cap_1, mint_cap_1) = coin::initialize<Warin>(
            test_acc,
            string::utf8(b"RewardCoin"),
            string::utf8(b"RC"),
            8,
            false,
        );
        coin::register<Warin>(test_acc);
        coin::register<Warin>(source_acc);
        //202_617_400
        let coins =coin::mint<Warin>(500_000_000,&mint_cap_1);      
        coin::deposit(signer::address_of(source_acc), coins);  
        coin::destroy_mint_cap(mint_cap_1);
        coin::destroy_freeze_cap(freeze_cap_1);        
        coin::destroy_burn_cap(burn_cap_1);   
    }
    
    #[test(test_acc=@aptos_framework,source_acc=@source_acc)]
    public entry fun create_lock(test_acc:&signer,source_acc:&signer)acquires Lock_resource{
        setup_enviroment(test_acc,source_acc);
        lock<AptosCoin>(test_acc,20000,20000,signer::address_of(source_acc));
        timestamp::fast_forward_seconds(30000);
        //check the lock
        let check_all_locks=getAllLocks<AptosCoin>(test_acc,signer::address_of(source_acc));
        assert!(vector::length(&check_all_locks)==1,0);
        update_rewards<AptosCoin>(test_acc,signer::address_of(source_acc));

    }

    #[test(test_acc=@aptos_framework,source_acc=@source_acc)]
    public entry fun test_batch(test_acc:&signer,source_acc:&signer) acquires Lock_resource{
        setup_enviroment(test_acc,source_acc);
        lock<AptosCoin>(test_acc,20000,20000,signer::address_of(source_acc));
        timestamp::fast_forward_seconds(30000);
        //Create the batch locally for test
        let batch=vector::empty<LockDetails>();
        vector::push_back(&mut batch,LockDetails{coins:23,unlock_time_sec:2000});
        vector::push_back(&mut batch,LockDetails{coins:66,unlock_time_sec:100});
        batchLock<AptosCoin>(test_acc,batch,signer::address_of(source_acc));
        //Check the lock
        let check_all_locks=getAllLocks<AptosCoin>(test_acc,signer::address_of(source_acc));
        assert!(vector::length(&check_all_locks)==3,0);
        // let reward_balance=coin::balance<Warin>(signer::address_of(source_acc));
        // print(&std::string::utf8(b"AAAA"));
        // print(&reward_balance);
        distributeFunds<AptosCoin,Warin>(source_acc,test_acc);
        assert!(coin::balance<AptosCoin>(signer::address_of(test_acc))==20000000,0);
        assert!(coin::balance<Warin>(signer::address_of(test_acc))==202617400,0);
    }

}