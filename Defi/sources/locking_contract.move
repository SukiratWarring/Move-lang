module myAddress::LockContract{
    use std::signer;
    // use std::account;
    use std::vector;
    use aptos_std::table::{Self,Table};
    use aptos_framework::coin;
    struct StakeDetails has store{
        coins: u64,
        unlock_time_sec:u64
    }

    struct Address_to_stake<phantom CoinType>{
        all_locks:Table<address, vector<StakeDetails>>,
    }

    public entry fun stake<CoinType>(account:&signer,unlock_time:u64,amt:u64){
        let stake_addr=signer::address_of(account);
        let address_to_stake =  borrow_global_mut<Address_to_stake<CoinType>>(stake_addr);
        let vec = if (table::contains(&address_to_stake.all_locks, stake_addr)) {
            table::borrow_mut(&mut address_to_stake.all_locks, stake_addr)
        } else {
            let v = vector::empty<StakeDetails>();
            table::add(&mut address_to_stake.all_locks, stake_addr, v);
            table::borrow_mut(&mut address_to_stake.all_locks, stake_addr)
        };

        // vector::push_back(&mut vec, 10);
        // table(&mut table.all_locks,stake_addr,)
        vector::push_back(&mut vec, StakeDetails{
            coins:amt,
            unlock_time_sec:unlock_time
        });
        // Table::add(&mut table, stake_addr, vec);
        // move_to(account,Address_to_stake<CoinType>{
        //     all_locks:table,
        // })

    }

    public entry fun un_stake(){

    }

    fun transfer_funds (){

    }

    public entry fun  calculate_reward(){

    }


}