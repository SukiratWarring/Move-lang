#[test_only]
module myAddress::res_acc_tests{
    use std::signer;
    use std::vector;
    use myAddress::Resource_account::{Self,ModuleData};
    use aptos_token::token::{Self,TokenStore};
    use aptos_framework::account::{Self,SignerCapability};
    use aptos_framework::account::create_account_for_test;
    use aptos_framework::resource_account;
    use std::debug::print;

    public entry fun setup_test_environment(res_acc: &signer,origin_account:signer,nft_receiver:&signer) {
        create_account_for_test(signer::address_of(&origin_account));
        // create a resource account from the origin account, mocking the module publishing process
        resource_account::create_resource_account(&origin_account, vector::empty<u8>(), vector::empty<u8>());
        create_account_for_test(signer::address_of(nft_receiver));
        Resource_account::init_test(res_acc,nft_receiver);
    }    
    

    #[test(
        res_acc = @0xc3bb8488ab1a5815a9d543d7e41b0e0df46a7396f89b22821f07a4362f75ddc5,
        origin_acc = @0xcafe,
        nft_rec_acc = @0x123,
        auth_account= @0x23123,
    )]
    #[expected_failure]
    public entry fun test_setup_and_mint(res_acc:signer,origin_acc:signer,nft_rec_acc:signer,auth_account:signer){
        setup_test_environment(&res_acc,origin_acc,&nft_rec_acc);
        Resource_account::mint(&nft_rec_acc);

        let token_id=Resource_account::get_tokenId();
        let amt=token::balance_of(signer::address_of(&nft_rec_acc), token_id);
        print<u64>(&amt);
        assert!(amt==1,0);

        


    }
}