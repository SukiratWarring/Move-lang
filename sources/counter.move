module myAddress::CounterContract{
    use std::signer;
    use std::debug::print;
    use std::string::utf8;
    struct GlobalCounter has key{
        counter:u64
    }

    public  fun getCounter(addr:address):u64 acquires GlobalCounter{
        assert!(exists<GlobalCounter>(addr),0);
        borrow_global<GlobalCounter>(addr).counter
    }

    public entry fun init(account:&signer){
        let addr=signer::address_of(account);
        if(!exists<GlobalCounter>(addr)){
            move_to(account,GlobalCounter{
                counter:0
            })
        }
        
    }

    public fun incrementCounter(account:&signer) acquires GlobalCounter{
        let addr=signer::address_of(account);
        if(exists<GlobalCounter>(addr)){
            let currValue=borrow_global_mut<GlobalCounter>(addr);
            currValue.counter=currValue.counter+1;
        }else{
            abort 42;
        }
    }    

    public fun decrementCounter(account:&signer) acquires GlobalCounter{
        let addr=signer::address_of(account);
        if(exists<GlobalCounter>(addr)){
            let currValue=borrow_global_mut<GlobalCounter>(addr).counter;

        }
    }
}