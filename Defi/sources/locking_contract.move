module myAddress::LockContract{
    use std::signer;
    use std::debug::print;
    use std::vector;
    use aptos_std::table::{Self,Table};
    use std::error;
    use std::timestamp;
    use aptos_framework::coin;

    const E_NOT_INITIALISED:u64=0;
    struct LockDetails has store,copy,drop{
        coins: u64,
        unlock_time_sec:u64
    }
    
    struct Address_to_lock<phantom CoinType> has key {
        all_locks:Table<address, vector<LockDetails>>,
    }

    public entry fun init<CoinType>(account:&signer){
        let addr=signer::address_of(account);
        let t=table::new<address, vector<LockDetails>>();
        move_to(account,Address_to_lock<CoinType>{
            all_locks: t,
        })

    }

    public entry fun lock<CoinType>(account:&signer,unlock_time:u64,amt:u64) acquires Address_to_lock{
        let lock_addr=signer::address_of(account);
        assert!(exists<Address_to_lock<CoinType>>(lock_addr),error::internal(E_NOT_INITIALISED));
        let address_to_lock =  borrow_global_mut<Address_to_lock<CoinType>>(lock_addr);
        let vec = if (table::contains(&address_to_lock.all_locks, lock_addr)) {
            table::borrow_mut(&mut address_to_lock.all_locks, lock_addr)
        } else {
            let v = vector::empty<LockDetails>();
            table::add(&mut address_to_lock.all_locks, lock_addr, v);
            table::borrow_mut(&mut address_to_lock.all_locks, lock_addr)
        };
        vector::push_back(vec, LockDetails{
            coins:amt,
            unlock_time_sec:unlock_time,
        });
    }

    fun calcualte_rewards<CoinType>(account:&signer):u64 acquires Address_to_lock{
        //get all locks
        let address_to_check =  borrow_global_mut<Address_to_lock<CoinType>>(signer::address_of(account));
        let all_locks=table::borrow_mut(&mut address_to_check.all_locks, signer::address_of(account));
        let total_rewards=0;
        vector::for_each_mut<LockDetails>(all_locks,|each_lock|{
            let lock:&mut LockDetails=each_lock;
            if(timestamp::now_seconds()>=lock.unlock_time_sec){
            let diffTime=timestamp::now_seconds()-lock.unlock_time_sec;
            let reward=lock.coins * diffTime;
            total_rewards=reward+total_rewards;
            print<LockDetails>(lock);
            } 
        });
        total_rewards

    }

    public fun distributeFunds<CoinType>(account:&signer)acquires Address_to_lock{
        let addr=signer::address_of(account);
        let rewards=calcualte_rewards<CoinType>(account);
        coin::transfer<CoinType>(account,addr, rewards);
    }

    public fun getAllLocks<CoinType>(account:&signer):vector<LockDetails> acquires Address_to_lock{
        let address_to_check =  borrow_global<Address_to_lock<CoinType>>(signer::address_of(account));
        *table::borrow(&address_to_check.all_locks, signer::address_of(account))

    }



}