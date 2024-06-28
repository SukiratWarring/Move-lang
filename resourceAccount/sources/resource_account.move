module myAddress::Resource_account{
    use std::string;

    use aptos_token::token;
    use std::signer;
    use std::vector;
    use std::string::String;
    use aptos_token::token::{TokenId,TokenDataId};
    use aptos_framework::account::{Self,SignerCapability};
    use aptos_framework::resource_account;
    // This struct stores an NFT collection's relevant information
    struct ModuleData has key {
        // Storing the signer capability here, so the module can programmatically sign for transactions
        signer_cap: SignerCapability,
        token_data_id: TokenDataId,
    } 

    fun init_module(resource_signer: &signer) {
        let collection_name = string::utf8(b"Collection name");
        let description = string::utf8(b"Description");
        let collection_uri = string::utf8(b"Collection uri");
        let token_name = string::utf8(b"Token name");
        let token_uri = string::utf8(b"Token uri");
        // This means that the supply of the token will not be tracked.
        let maximum_supply = 0;
        // This variable sets if we want to allow mutation for collection description, uri, and maximum.
        // Here, we are setting all of them to false, which means that we don't allow mutations to any CollectionData fields.
        let mutate_setting = vector<bool>[ false, false, false ];

        // Create the nft collection.
        token::create_collection(resource_signer, collection_name, description, collection_uri, maximum_supply, mutate_setting);

        // Create a token data id to specify the token to be minted.
        let token_data_id = token::create_tokendata(
            resource_signer,
            collection_name,
            token_name,
            string::utf8(b""),
            0,
            token_uri,
            signer::address_of(resource_signer),
            1,
            0,
            // This variable sets if we want to allow mutation for token maximum, uri, royalty, description, and properties.
            // Here we enable mutation for properties by setting the last boolean in the vector to true.
            token::create_token_mutability_config(
                &vector<bool>[ false, false, false, false, true ]
            ),
            // We can use property maps to record attributes related to the token.
            // In this example, we are using it to record the receiver's address.
            // We will mutate this field to record the user's address
            // when a user successfully mints a token in the `mint_event_ticket()` function.
            vector<String>[string::utf8(b"given_to")],
            vector<vector<u8>>[b""],
            vector<String>[ string::utf8(b"address") ],
        );

        // Retrieve the resource signer's signer capability and store it within the `ModuleData`.
        // Note that by calling `resource_account::retrieve_resource_account_cap` to retrieve the resource account's signer capability,
        // we rotate th resource account's authentication key to 0 and give up our control over the resource account. Before calling this function,
        // the resource account has the same authentication key as the source account so we had control over the resource account.
        let resource_signer_cap = resource_account::retrieve_resource_account_cap(resource_signer,@source_addr);

        // Store the token data id and the resource account's signer capability within the module, so we can programmatically
        // sign for transactions in the `mint_event_ticket()` function.
        move_to(resource_signer, ModuleData {
            signer_cap: resource_signer_cap,
            token_data_id,
        });
    }

    public fun mint(receiver:&signer)acquires ModuleData{
        //Fetching the data stored at the contract
        let module_data=borrow_global_mut<ModuleData>(@myAddress);
        // Creating the signer from the stored singer cap
        let resource_signer=account::create_signer_with_capability(&module_data.signer_cap);
        //Tokenid of the minted token
        let tokenId=token::mint_token(&resource_signer,module_data.token_data_id,1);
        //Sending it to the receiver
        token::direct_transfer(&resource_signer,receiver,tokenId,1);
        
        //Fetching all details for the collection from the token_data_id
        let (creator_address, collection, name)=token::get_token_data_id_fields(&module_data.token_data_id);        
        // Mutate the token properties to update the property version of this token.
        // Note that here we are re-using the same token data id and only updating the property version.
        // This is because we are simply printing edition of the same token, instead of creating unique
        // tokens. The tokens created this way will have the same token data id, but different property versions.        
        token::mutate_token_properties(
            &resource_signer,
            signer::address_of(receiver),
            creator_address,
            collection,
            name,
            0,
            1,
            vector::empty<String>(),
            vector::empty<vector<u8>>(),
            vector::empty<String>(),
        );
        

    }
    #[view]
    public fun get_tokenId():TokenId acquires ModuleData{
        let module_data=borrow_global_mut<ModuleData>(@myAddress);
        let resource_signer = account::create_signer_with_capability(&module_data.signer_cap);
        let resource_signer_addr = signer::address_of(&resource_signer);
        let token_id = token::create_token_id_raw(
            resource_signer_addr,
            string::utf8(b"Collection name"),
            string::utf8(b"Token name"),
            1
        );      
        token_id  
    }

    #[test_only]
    public fun init_test(acc:&signer,nft_rec_acc:&signer)acquires ModuleData{
        init_module(acc);
        mint(nft_rec_acc);
    } 

}