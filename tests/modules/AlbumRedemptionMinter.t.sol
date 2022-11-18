pragma solidity ^0.8.16;

import { IERC165 } from "openzeppelin/utils/introspection/IERC165.sol";
import { SoundEditionV1a } from "@core/SoundEditionV1a.sol";
import { SoundEditionV1 } from "@core/SoundEditionV1.sol";
import { SoundCreatorV1 } from "@core/SoundCreatorV1.sol";
import { AlbumRedemptionMinter } from "@modules/AlbumRedemptionMinter.sol";
import { IAlbumRedemptionMinter, MintInfo } from "@modules/interfaces/IAlbumRedemptionMinter.sol";
import { MockRarityShuffleMetadata } from "../mocks/MockRarityShuffleMetadata.sol";
import { IMinterModule } from "@core/interfaces/IMinterModule.sol";
import { BaseMinter } from "@modules/BaseMinter.sol";
import { TestConfig } from "../TestConfigv1a.sol";

error LogAddy(address a);

contract AlbumRedemptionMinterTests is TestConfig {

    uint32 constant START_TIME = 100;

    uint32 constant END_TIME = 300;

    uint32 constant MAX_MINTABLE_LOWER = 5;

    uint32 constant MAX_MINTABLE_UPPER = 10;

    uint128 constant MINT_ID = 0;

    uint32 constant REQUIRED_REDEMPTIONS = 6;

    uint32 constant MAX_MINTABLE_PER_ACCOUNT = type(uint32).max;

    function _createEditionAndMinter(uint32 _maxMintablePerAccount)
        internal
        returns (SoundEditionV1a edition, SoundEditionV1 albumEdition, AlbumRedemptionMinter minter)
    {
        edition = createGenericEdition();

        edition.setEditionMaxMintableRange(MAX_MINTABLE_LOWER, MAX_MINTABLE_UPPER);
        
        albumEdition = createEditionWithNoModule();
        

        minter = new AlbumRedemptionMinter(feeRegistry);

        albumEdition.grantRoles(address(minter), albumEdition.MINTER_ROLE());

        minter.createAlbumRedemptionMint(
            address(edition),
            address(albumEdition),
            6,
            START_TIME,
            END_TIME,
            _maxMintablePerAccount
        );
    }

    // function test_createAlbumRedemptionMint(
    //     uint32 startTime,
    //     uint32 endTime,
    //     uint32 maxMintablePerAccount
    // ) public {
    //     SoundEditionV1a edition = SoundEditionV1a(
    //         createSound(
    //             SONG_NAME,
    //             SONG_SYMBOL,
    //             BASE_URI,
    //             CONTRACT_URI,
    //             FUNDING_RECIPIENT,
    //             ROYALTY_BPS,
    //             EDITION_MAX_MINTABLE,
    //             EDITION_MAX_MINTABLE,
    //             EDITION_CUTOFF_TIME,
    //             FLAGS
    //         )
    //     );

    //     SoundEditionV1a albumEdition = SoundEditionV1a(
    //         createSound(
    //             SONG_NAME,
    //             SONG_SYMBOL,
    //             BASE_URI,
    //             CONTRACT_URI,
    //             FUNDING_RECIPIENT,
    //             ROYALTY_BPS,
    //             EDITION_MAX_MINTABLE,
    //             EDITION_MAX_MINTABLE,
    //             EDITION_CUTOFF_TIME,
    //             FLAGS
    //         )
    //     );

    //     AlbumRedemptionMinter minter = new AlbumRedemptionMinter(feeRegistry);

    //     bool hasRevert;

    //     if (maxMintablePerAccount == 0) {
    //         vm.expectRevert(IAlbumRedemptionMinter.MaxMintablePerAccountIsZero.selector);
    //         hasRevert = true;
    //     } else if (!(startTime < endTime)) {
    //         vm.expectRevert(IMinterModule.InvalidTimeRange.selector);
    //         hasRevert = true;
    //     } 
        
    //     minter.createAlbumRedemptionMint(address(edition), address(albumEdition), REQUIRED_REDEMPTIONS, startTime, endTime, maxMintablePerAccount);

    //     if (!hasRevert) {
    //         MintInfo memory mintInfo = minter.mintInfo(address(edition), MINT_ID);

    //         assertEq(mintInfo.requiredRedemptions, REQUIRED_REDEMPTIONS);
    //         assertEq(mintInfo.redemptionContract, address(edition));
    //         assertEq(mintInfo.startTime, startTime);
    //         assertEq(mintInfo.endTime, endTime);
    //     }
    // }
    
    // Revert if wrong token array
    // Revert if right token array but not owned
    // Happy case
    //  Burns all
    //  Mints
    
    function test_mintsAlbumAndBurnsSongsWhenSatisfied() public {
        (SoundEditionV1a edition, SoundEditionV1 albumEdition, AlbumRedemptionMinter minter) = _createEditionAndMinter(1);
        vm.warp(START_TIME);

        address caller = getFundedAccount(1);
        
        // Mint 6
        address owner = address(12345);
        edition.transferOwnership(owner);
        vm.prank(owner);
        edition.mint(caller, 6);
        vm.startPrank(caller);
        
        // Set shuffled IDs for each
        MockRarityShuffleMetadata module = MockRarityShuffleMetadata(edition.metadataModule());
        module.setOffset(6, _ranges[0]);
        module.setOffset(3, _ranges[1]);
        module.setOffset(4, _ranges[2]);
        module.setOffset(2, _ranges[3]);
        module.setOffset(5, _ranges[4]);
        module.setOffset(1, _ranges[5]);
        
        
        edition.setApprovalForAll(address(minter), true);

        uint256[] memory _tokens = new uint256[](6);
        _tokens[0] = 6;
        _tokens[1] = 3;
        _tokens[2] = 4;
        _tokens[3] = 2;
        _tokens[4] = 5;
        _tokens[5] = 1;
        

        minter.mint(address(albumEdition), address(edition), 0, _tokens);
        
        assert(edition.numberBurned(caller) == 6);
        assert(albumEdition.numberMinted(caller) == 1);
        
    }

    // function test_mintWhenOverMaxMintablePerAccountReverts() public {
    //     (SoundEditionV1a edition, AlbumRedemptionMinter minter) = _createEditionAndMinter(1);
    //     vm.warp(START_TIME);

    //     address caller = getFundedAccount(1);
    //     vm.prank(caller);
    //     vm.expectRevert(IAlbumRedemptionMinter.ExceedsMaxPerAccount.selector);
    //     minter.mint{ value: PRICE * 2 }(address(edition), MINT_ID, 2, address(0));
    // }

    // function test_mintWhenOverMaxMintableDueToPreviousMintedReverts() public {
    //     (SoundEditionV1a edition, AlbumRedemptionMinter minter) = _createEditionAndMinter(3);
    //     vm.warp(START_TIME);

    //     address caller = getFundedAccount(1);

    //     // have 2 previously minted
    //     address owner = address(12345);
    //     edition.transferOwnership(owner);
    //     vm.prank(owner);
    //     edition.mint(caller, 2);

    //     // attempting to mint 2 more reverts
    //     vm.prank(caller);
    //     vm.expectRevert(IAlbumRedemptionMinter.ExceedsMaxPerAccount.selector);
    //     minter.mint{ value: PRICE * 2 }(address(edition), MINT_ID, 2, address(0));
    // }

    // function test_mintWhenMintablePerAccountIsSetAndSatisfied() public {
    //     // Set max allowed per account to 3
    //     (SoundEditionV1a edition, AlbumRedemptionMinter minter) = _createEditionAndMinter(3);

    //     address caller = getFundedAccount(1);

    //     // Set 1 previous mint
    //     address owner = address(12345);
    //     edition.transferOwnership(owner);
    //     vm.prank(owner);
    //     edition.mint(caller, 1);

    //     // Ensure we can mint the max allowed of 2 tokens
    //     vm.warp(START_TIME);
    //     vm.prank(caller);
    //     minter.mint{ value: PRICE * 2 }(address(edition), MINT_ID, 2, address(0));

    //     assertEq(edition.balanceOf(caller), 3);

    //     assertEq(edition.totalMinted(), 3);
    // }

    // function test_mintUpdatesValuesAndMintsCorrectly() public {
    //     (SoundEditionV1a edition, AlbumRedemptionMinter minter) = _createEditionAndMinter(type(uint32).max);

    //     vm.warp(START_TIME);

    //     address caller = getFundedAccount(1);

    //     uint32 quantity = 2;

    //     assertEq(edition.totalMinted(), 0);

    //     vm.prank(caller);
    //     minter.mint{ value: PRICE * quantity }(address(edition), MINT_ID, quantity, address(0));

    //     assertEq(edition.balanceOf(caller), uint256(quantity));

    //     assertEq(edition.totalMinted(), quantity);
    // }

    // function test_mintRevertForUnderpaid() public {
    //     uint32 quantity = 2;
    //     (SoundEditionV1a edition, AlbumRedemptionMinter minter) = _createEditionAndMinter(quantity);

    //     vm.warp(START_TIME);

    //     uint256 requiredPayment = quantity * PRICE;

    //     bytes memory expectedRevert = abi.encodeWithSelector(
    //         IMinterModule.Underpaid.selector,
    //         requiredPayment - 1,
    //         requiredPayment
    //     );

    //     vm.expectRevert(expectedRevert);
    //     minter.mint{ value: requiredPayment - 1 }(address(edition), MINT_ID, quantity, address(0));
    // }

    // function test_mintRevertsForMintNotOpen() public {
    //     (SoundEditionV1a edition, AlbumRedemptionMinter minter) = _createEditionAndMinter(type(uint32).max);

    //     uint32 quantity = 1;

    //     vm.warp(START_TIME - 1);
    //     vm.expectRevert(
    //         abi.encodeWithSelector(IMinterModule.MintNotOpen.selector, block.timestamp, START_TIME, END_TIME)
    //     );
    //     minter.mint{ value: quantity * PRICE }(address(edition), MINT_ID, quantity, address(0));

    //     vm.warp(START_TIME);
    //     minter.mint{ value: quantity * PRICE }(address(edition), MINT_ID, quantity, address(0));

    //     vm.warp(CUTOFF_TIME);
    //     minter.mint{ value: quantity * PRICE }(address(edition), MINT_ID, quantity, address(0));

    //     vm.warp(END_TIME);
    //     minter.mint{ value: quantity * PRICE }(address(edition), MINT_ID, quantity, address(0));

    //     vm.warp(END_TIME + 1);
    //     vm.expectRevert(
    //         abi.encodeWithSelector(IMinterModule.MintNotOpen.selector, block.timestamp, START_TIME, END_TIME)
    //     );
    //     minter.mint{ value: quantity * PRICE }(address(edition), MINT_ID, quantity, address(0));
    // }

    // function test_setPrice(uint96 price) public {
    //     (SoundEditionV1a edition, AlbumRedemptionMinter minter) = _createEditionAndMinter(type(uint32).max);

    //     vm.expectEmit(true, true, true, true);
    //     emit PriceSet(address(edition), MINT_ID, price);
    //     minter.setPrice(address(edition), MINT_ID, price);

    //     assertEq(minter.mintInfo(address(edition), MINT_ID).price, price);
    // }

    // function test_setMaxMintablePerAccount(uint32 maxMintablePerAccount) public {
    //     vm.assume(maxMintablePerAccount != 0);
    //     (SoundEditionV1a edition, AlbumRedemptionMinter minter) = _createEditionAndMinter(type(uint32).max);

    //     vm.expectEmit(true, true, true, true);
    //     emit MaxMintablePerAccountSet(address(edition), MINT_ID, maxMintablePerAccount);
    //     minter.setMaxMintablePerAccount(address(edition), MINT_ID, maxMintablePerAccount);

    //     assertEq(minter.mintInfo(address(edition), MINT_ID).maxMintablePerAccount, maxMintablePerAccount);
    // }

    // function test_setZeroMaxMintablePerAccountReverts() public {
    //     (SoundEditionV1a edition, AlbumRedemptionMinter minter) = _createEditionAndMinter(type(uint32).max);

    //     vm.expectRevert(IAlbumRedemptionMinter.MaxMintablePerAccountIsZero.selector);
    //     minter.setMaxMintablePerAccount(address(edition), MINT_ID, 0);
    // }

    // function test_createWithZeroMaxMintablePerAccountReverts() public {
    //     (SoundEditionV1a edition, AlbumRedemptionMinter minter) = _createEditionAndMinter(type(uint32).max);

    //     vm.expectRevert(IAlbumRedemptionMinter.MaxMintablePerAccountIsZero.selector);
    //     minter.createAlbumRedemptionMint(address(edition), PRICE, START_TIME, END_TIME, AFFILIATE_FEE_BPS, 0);
    // }

    // function test_supportsInterface() public {
    //     (, AlbumRedemptionMinter minter) = _createEditionAndMinter(type(uint32).max);

    //     bool supportsIMinterModule = minter.supportsInterface(type(IMinterModule).interfaceId);
    //     bool supportsIAlbumRedemptionMinter = minter.supportsInterface(type(IAlbumRedemptionMinter).interfaceId);
    //     bool supports165 = minter.supportsInterface(type(IERC165).interfaceId);

    //     assertTrue(supports165);
    //     assertTrue(supportsIAlbumRedemptionMinter);
    //     assertTrue(supportsIMinterModule);
    // }

    // function test_moduleInterfaceId() public {
    //     (, AlbumRedemptionMinter minter) = _createEditionAndMinter(type(uint32).max);

    //     assertTrue(type(IAlbumRedemptionMinter).interfaceId == minter.moduleInterfaceId());
    // }

    // function test_mintInfo(
    //     uint96 price,
    //     uint32 startTime,
    //     uint32 endTime,
    //     uint16 affiliateFeeBPS,
    //     uint32 maxMintablePerAccount,
    //     uint32 editionMaxMintableLower,
    //     uint32 editionMaxMintableUpper,
    //     uint32 editionCutOffTime
    // ) public {
    //     vm.assume(startTime < endTime);
    //     vm.assume(editionMaxMintableLower <= editionMaxMintableUpper);

    //     affiliateFeeBPS = uint16(affiliateFeeBPS % MAX_BPS);

    //     uint32 quantity = 4;

    //     if (maxMintablePerAccount < quantity) maxMintablePerAccount = quantity;
    //     if (editionMaxMintableLower < quantity) editionMaxMintableLower = quantity;
    //     if (editionMaxMintableUpper < quantity) editionMaxMintableUpper = quantity;

    //     SoundEditionV1a edition = SoundEditionV1a(
    //         createSound(
    //             SONG_NAME,
    //             SONG_SYMBOL,
    //             METADATA_MODULE,
    //             BASE_URI,
    //             CONTRACT_URI,
    //             FUNDING_RECIPIENT,
    //             ROYALTY_BPS,
    //             editionMaxMintableLower,
    //             editionMaxMintableUpper,
    //             editionCutOffTime,
    //             FLAGS
    //         )
    //     );

    //     AlbumRedemptionMinter minter = new AlbumRedemptionMinter(feeRegistry);

    //     edition.grantRoles(address(minter), edition.MINTER_ROLE());

    //     minter.createAlbumRedemptionMint(address(edition), price, startTime, endTime, affiliateFeeBPS, maxMintablePerAccount);

    //     MintInfo memory mintInfo = minter.mintInfo(address(edition), MINT_ID);

    //     assertEq(startTime, mintInfo.startTime);
    //     assertEq(endTime, mintInfo.endTime);
    //     assertEq(affiliateFeeBPS, mintInfo.affiliateFeeBPS);
    //     assertEq(false, mintInfo.mintPaused);
    //     assertEq(price, mintInfo.price);
    //     assertEq(maxMintablePerAccount, mintInfo.maxMintablePerAccount);
    //     assertEq(editionMaxMintableLower, mintInfo.maxMintableLower);
    //     assertEq(editionMaxMintableUpper, mintInfo.maxMintableUpper);
    //     assertEq(editionCutOffTime, mintInfo.cutoffTime);

    //     assertEq(0, edition.totalMinted());

    //     // Warp to start time & mint some tokens to test that totalMinted changed
    //     vm.warp(startTime);
    //     vm.deal(address(this), uint256(mintInfo.price) * uint256(quantity));
    //     minter.mint{ value: uint256(mintInfo.price) * uint256(quantity) }(
    //         address(edition),
    //         MINT_ID,
    //         quantity,
    //         address(0)
    //     );

    //     mintInfo = minter.mintInfo(address(edition), MINT_ID);

    //     assertEq(quantity, edition.totalMinted());
    // }

    // function test_mintInfo() public {
    //     test_mintInfo(
    //         123123, /* price */
    //         100, /* startTime */
    //         200, /* endTime */
    //         10, /* affiliateFeeBPS */
    //         100, /* maxMintablePerAccount */
    //         1111, /* editionMaxMintableLower */
    //         2222, /* editionMaxMintableUpper */
    //         150 /* editionCutOffTime*/
    //     );
    // }
}
