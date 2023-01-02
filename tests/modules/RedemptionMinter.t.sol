pragma solidity ^0.8.16;

import { IERC165 } from "openzeppelin/utils/introspection/IERC165.sol";
import { IERC721AUpgradeable } from "chiru-labs/ERC721A-Upgradeable/IERC721AUpgradeable.sol";
import { SoundEditionV1 } from "@core/SoundEditionV1.sol";
import { SoundCreatorV1 } from "@core/SoundCreatorV1.sol";
import { RedemptionMinter } from "@modules/RedemptionMinter.sol";
import { IRedemptionMinter, MintInfo } from "@modules/interfaces/IRedemptionMinter.sol";
import { IMinterModule } from "@core/interfaces/IMinterModule.sol";
import { BaseMinter } from "@modules/BaseMinter.sol";
import { TestConfig } from "../TestConfig.sol";

error LogAddy(address a);

contract RedemptionMinterTests is TestConfig {

    uint32 constant START_TIME = 100;

    uint32 constant END_TIME = 300;

    uint32 constant MAX_MINTABLE_LOWER = 5;

    uint32 constant MAX_MINTABLE_UPPER = 10;

    uint128 constant MINT_ID = 0;

    uint32 constant REQUIRED_REDEMPTIONS = 6;

    uint32 constant MAX_MINTABLE_PER_ACCOUNT = type(uint32).max;

    function _createEditionAndMinter(uint32 _maxMintablePerAccount)
        internal
        returns (SoundEditionV1 edition, SoundEditionV1 secretEdition, RedemptionMinter minter)
    {
        edition = createGenericEdition();

        edition.setEditionMaxMintableRange(MAX_MINTABLE_LOWER, MAX_MINTABLE_UPPER);
        
        secretEdition = createGenericEdition();
        

        minter = new RedemptionMinter(feeRegistry);

        secretEdition.grantRoles(address(minter), secretEdition.MINTER_ROLE());

        minter.createRedemptionMint(
            address(edition),
            address(secretEdition),
            4,
            START_TIME,
            END_TIME,
            _maxMintablePerAccount
        );
    }

    // Happy case
    //  Burns all
    //  Mints
    
    function test_mintsSecretAndBurnsSongsWhenSatisfied() public {
        (SoundEditionV1 edition, SoundEditionV1 secretEdition, RedemptionMinter minter) = _createEditionAndMinter(1);
        vm.warp(START_TIME);

        address caller = getFundedAccount(1);
        
        // Mint 6
        address owner = address(12345);
        edition.transferOwnership(owner);
        vm.prank(owner);
        edition.mint(caller, 6);
        vm.startPrank(caller);
        
        
        edition.setApprovalForAll(address(minter), true);

        uint256[] memory _tokens = new uint256[](4);
        _tokens[0] = 6;
        _tokens[1] = 3;
        _tokens[2] = 4;
        _tokens[3] = 2;
        

        minter.mint(address(secretEdition), 0, _tokens);
        
        assert(edition.numberBurned(caller) == 4);
        assert(secretEdition.numberMinted(caller) == 1);

    }
    
    function test_failsIfTokenNotOwned() public {
        (SoundEditionV1 edition, SoundEditionV1 secretEdition, RedemptionMinter minter) = _createEditionAndMinter(1);
        vm.warp(START_TIME);

        address caller = getFundedAccount(1);
        address someoneElse = getFundedAccount(2);
        
        // Mint 6
        address owner = address(12345);
        edition.transferOwnership(owner);
        vm.prank(owner);
        edition.mint(someoneElse, 6);
        vm.startPrank(caller);

        uint256[] memory _tokens = new uint256[](4);
        _tokens[0] = 6;
        _tokens[1] = 3;
        _tokens[2] = 4;
        _tokens[3] = 2;
        

        vm.expectRevert(IRedemptionMinter.OfferedTokenNotOwned.selector);
        minter.mint(address(secretEdition), 0, _tokens);
        
    }

    function test_failsIfTokensDoNotExist() public {
        (SoundEditionV1 edition, SoundEditionV1 secretEdition, RedemptionMinter minter) = _createEditionAndMinter(1);
        vm.warp(START_TIME);

        address caller = getFundedAccount(1);
        address someoneElse = getFundedAccount(2);
        
        vm.startPrank(caller);

        uint256[] memory _tokens = new uint256[](4);
        _tokens[0] = 6;
        _tokens[1] = 3;
        _tokens[2] = 4;
        _tokens[3] = 2;
        

        vm.expectRevert(IERC721AUpgradeable.OwnerQueryForNonexistentToken.selector);
        minter.mint(address(secretEdition), 0, _tokens);
        
    }
    
    function test_failsIfTokensCannotExist() public {
        (SoundEditionV1 edition, SoundEditionV1 secretEdition, RedemptionMinter minter) = _createEditionAndMinter(1);
        vm.warp(START_TIME);

        address caller = getFundedAccount(1);
        address someoneElse = getFundedAccount(2);
        
        vm.startPrank(caller);

        uint256[] memory _tokens = new uint256[](4);
        _tokens[0] = 0;
        _tokens[1] = 0;
        _tokens[2] = 0;
        _tokens[3] = 0;
        

        vm.expectRevert(IERC721AUpgradeable.OwnerQueryForNonexistentToken.selector);
        minter.mint(address(secretEdition), 0, _tokens);
        
    }


    function test_failsIfSomeTokensNotOwned() public {
        (SoundEditionV1 edition, SoundEditionV1 secretEdition, RedemptionMinter minter) = _createEditionAndMinter(1);
        vm.warp(START_TIME);

        address caller = getFundedAccount(1);
        address someoneElse = getFundedAccount(2);
        
        // Mint 6
        address owner = address(12345);
        edition.transferOwnership(owner);
        vm.prank(owner);
        edition.mint(caller, 6);

        vm.startPrank(caller);
        edition.setApprovalForAll(address(minter), true);
        edition.safeTransferFrom(caller, someoneElse, 2);

        uint256[] memory _tokens = new uint256[](4);
        _tokens[0] = 6;
        _tokens[1] = 3;
        _tokens[2] = 4;
        _tokens[3] = 2;
        

        vm.expectRevert(IRedemptionMinter.OfferedTokenNotOwned.selector);
        minter.mint(address(secretEdition), 0, _tokens);
        
    }

    function test_failsIfSomeTokensDoNotExist() public {
        (SoundEditionV1 edition, SoundEditionV1 secretEdition, RedemptionMinter minter) = _createEditionAndMinter(1);
        vm.warp(START_TIME);

        address caller = getFundedAccount(1);
        
        // Mint 6
        address owner = address(12345);
        edition.transferOwnership(owner);
        vm.prank(owner);
        edition.mint(caller, 6);

        vm.startPrank(caller);
        edition.setApprovalForAll(address(minter), true);

        uint256[] memory _tokens = new uint256[](4);
        _tokens[0] = 6;
        _tokens[1] = 3;
        _tokens[2] = 4;
        _tokens[3] = 7;
        

        vm.expectRevert(IERC721AUpgradeable.OwnerQueryForNonexistentToken.selector);
        minter.mint(address(secretEdition), 0, _tokens);
        
    }
    
    function test_failsIfTokensRepeated() public {
        (SoundEditionV1 edition, SoundEditionV1 secretEdition, RedemptionMinter minter) = _createEditionAndMinter(1);
        vm.warp(START_TIME);

        address caller = getFundedAccount(1);
        
        // Mint 6
        address owner = address(12345);
        edition.transferOwnership(owner);
        vm.prank(owner);
        edition.mint(caller, 6);

        vm.startPrank(caller);
        edition.setApprovalForAll(address(minter), true);

        uint256[] memory _tokens = new uint256[](4);
        _tokens[0] = 6;
        _tokens[1] = 3;
        _tokens[2] = 4;
        _tokens[3] = 6;
        

        vm.expectRevert(IERC721AUpgradeable.OwnerQueryForNonexistentToken.selector);
        minter.mint(address(secretEdition), 0, _tokens);
        
    }


    function test_failsIfTokenNotApproved() public {
        (SoundEditionV1 edition, SoundEditionV1 secretEdition, RedemptionMinter minter) = _createEditionAndMinter(1);
        vm.warp(START_TIME);

        address caller = getFundedAccount(1);
        
        // Mint 6
        address owner = address(12345);
        edition.transferOwnership(owner);
        vm.prank(owner);
        edition.mint(caller, 6);

        vm.startPrank(caller);

        uint256[] memory _tokens = new uint256[](4);
        _tokens[0] = 6;
        _tokens[1] = 3;
        _tokens[2] = 4;
        _tokens[3] = 2;
        

        vm.expectRevert(IERC721AUpgradeable.TransferCallerNotOwnerNorApproved.selector);
        minter.mint(address(secretEdition), 0, _tokens);
        
    }

    function test_failsIfTooManyTokens() public {
        (SoundEditionV1 edition, SoundEditionV1 secretEdition, RedemptionMinter minter) = _createEditionAndMinter(1);
        vm.warp(START_TIME);

        address caller = getFundedAccount(1);
        
        // Mint 6
        address owner = address(12345);
        edition.transferOwnership(owner);
        vm.prank(owner);
        edition.mint(caller, 6);
        vm.startPrank(caller);
        
        
        edition.setApprovalForAll(address(minter), true);

        uint256[] memory _tokens = new uint256[](5);
        _tokens[0] = 6;
        _tokens[1] = 3;
        _tokens[2] = 4;
        _tokens[3] = 2;
        _tokens[4] = 1;
        

        vm.expectRevert(IRedemptionMinter.InvalidNumberOfTokensOffered.selector);
        minter.mint(address(secretEdition), 0, _tokens);

    }

    function test_failsIfTooFewTokens() public {
        (SoundEditionV1 edition, SoundEditionV1 secretEdition, RedemptionMinter minter) = _createEditionAndMinter(1);
        vm.warp(START_TIME);

        address caller = getFundedAccount(1);
        
        // Mint 6
        address owner = address(12345);
        edition.transferOwnership(owner);
        vm.prank(owner);
        edition.mint(caller, 6);
        vm.startPrank(caller);
        
        
        edition.setApprovalForAll(address(minter), true);

        uint256[] memory _tokens = new uint256[](3);
        _tokens[0] = 6;
        _tokens[1] = 3;
        _tokens[2] = 4;
        

        vm.expectRevert(IRedemptionMinter.InvalidNumberOfTokensOffered.selector);
        minter.mint(address(secretEdition), 0, _tokens);

    }

    function test_AllowsAdminToSetMaxMintable() public {
        (SoundEditionV1 edition, SoundEditionV1 secretEdition, RedemptionMinter minter) = _createEditionAndMinter(1);

        address owner = address(12345);
        edition.transferOwnership(owner);
        vm.startPrank(owner);
        
        minter.setMaxMintablePerAccount(address(edition), 0, 5);

    }

    function test_FailsToSetMintableIfNotOwned() public {
        (SoundEditionV1 edition, SoundEditionV1 secretEdition, RedemptionMinter minter) = _createEditionAndMinter(1);

        address owner = address(12345);
        vm.startPrank(owner);
        
        vm.expectRevert(IMinterModule.Unauthorized.selector);
        minter.setMaxMintablePerAccount(address(edition), 0, 5);

    }
    
    function test_FailsToSetMintableToZero() public {
        (SoundEditionV1 edition, SoundEditionV1 secretEdition, RedemptionMinter minter) = _createEditionAndMinter(1);

        address owner = address(12345);
        edition.transferOwnership(owner);
        vm.startPrank(owner);
        
        vm.expectRevert(IRedemptionMinter.MaxMintablePerAccountIsZero.selector);
        minter.setMaxMintablePerAccount(address(edition), 0, 0);

    }

}
