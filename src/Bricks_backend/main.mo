import Nat "mo:base/Nat";
import Principal "mo:base/Principal";
import Bool "mo:base/Bool";
import Buffer "mo:base/Buffer";
import HashMap "mo:base/HashMap";
import Blob "mo:base/Blob";
import Dip720 "Utils/DIP720";
import ICRC "Utils/ICRC";

actor {
  type Asset = {
    asset_creator : Principal;
    admin_canister_ID : Principal;
    auction_is_active : Bool;
    value_per_mint : Nat;
    asset_details : Blob;
  };

  let ckBTC : Principal = Principal.fromText("aaaaa-aa");
  let asset_principal_List = Buffer.Buffer<Principal>(3);

  let asset_map = HashMap.HashMap<Principal, Asset>(1, Principal.equal, Principal.hash);

  public query func getAssetList() : async [Principal] {
    return _getAssetList();
  };

  public query func getAsset(asset_principal : Principal) : async {
    #Ok : Asset;
    #Err : Text;
  } {
    return _getAsset(asset_principal);
  };

  public func addAsset(asset_principal : Principal, asset : Asset) : () {
    asset_principal_List.add(asset_principal);
    asset_map.put(asset_principal, asset);
  };

  public shared ({ caller }) func mintAsset(asset_principal : Principal) : async {
    #Ok : Text;
    #Err : Text;
  } {
    if (await _mintAssetConditions(asset_principal, caller)) {
      return #Err("Insufficient ckBTC Balance");
    };
    let asset_nft_canister : Dip720.Dip721NFT = actor (Principal.toText(asset_principal));
    ignore (asset_nft_canister.mintDip721(caller, [{ purpose = #Preview; key_val_data = [{ key = "First"; val = #TextContent("Cool") }]; data = null }]));
    return #Ok("Sucessful");
  };

  private func _mintAssetConditions(asset_principal : Principal, caller : Principal) : async Bool {
    let asset : Asset = switch (asset_map.get(asset_principal)) {
      case (?res) { res };
      case (_) { return false };
    };
    if (not asset.auction_is_active) {
      return false;
    };
    let token : ICRC.Token = actor (Principal.toText(ckBTC));
    let txValid = switch (await token.icrc2_transfer_from({ spender_subaccount = null; from = { owner = caller; subaccount = null }; to = { owner = asset.asset_creator; subaccount = null }; amount = asset.value_per_mint; fee = null; memo = null; created_at_time = null })) {
      case (#Ok(res)) { res };
      case (#Err(err)) { return false };
    };
    return true;
  };

  private func _getAssetList() : [Principal] {
    return Buffer.toArray(asset_principal_List);
  };
  private func _getAsset(asset_principal : Principal) : {
    #Err : Text;
    #Ok : Asset;
  } {
    let asset = switch (asset_map.get(asset_principal)) {
      case (?res) { #Ok(res) };
      case (_) { #Err("Not Found") };
    };
  };
};
