module basic_move::basic_move;

// Imports

use std::string::{String, utf8};

use sui::test_scenario;


// Exception Codes

/// Hero ID is invalid
const EInvalidHeroId: u64 = 0x1;
/// Hero already has a weapon equipped
const EAlreadyEquippedWeapon: u64 = 0x2;
/// Hero does not have a weapon equipped
const EWeaponNotEquipped: u64 = 0x3;
// Weapon fields are not valid
const EInvalidWeaponFields: u64 = 0x4;


// Init


// Structs

public struct Hero has key {
    id: UID,
    name: String,
    stamina: u64,
    weapon: Option<Weapon>
}

public struct Weapon has key, store {
    id: UID,
    name: String,
    power: u64
}


// Functions

/// Mint a hero
/// 
/// # Arguments
/// 
/// * `name_param`: The name of the hero
/// * `stamina_param`: The stamina of the hero
/// * `ctx`: The transaction context
/// 
/// # Returns
/// 
/// * `Hero`: The hero that was minted
public fun mint_hero(
    name_param: String,
    stamina_param: u64,
    ctx: &mut TxContext
): Hero {
    let aHero = Hero {
        id: object::new(ctx),
        name: name_param,
        stamina: stamina_param,
        weapon: option::none()
    };
    aHero
}

/// Mint a weapon
/// 
/// # Arguments
/// 
/// * `name_param`: The name of the weapon
/// * `power_param`: The power of the weapon
/// * `ctx`: The transaction context
/// 
/// # Returns
/// 
/// * `Weapon`: The weapon that was minted
public fun mint_weapon(
    name_param: String,
    power_param: u64,
    ctx: &mut TxContext
): Weapon {
    Weapon {
        id: object::new(ctx),
        name: name_param,
        power: power_param
    }
}

/// Equip a weapon to a hero
/// 
/// # Arguments
/// 
/// * `hero`: The hero to equip the weapon to
/// * `weapon`: The weapon to equip
/// 
/// # Returns
/// 
/// * `Hero`: The hero that was equipped with the weapon
public fun equip_weapon(hero: &mut Hero, weapon: Weapon) {
    // Check if hero already has a weapon equipped
    assert!(hero.weapon.is_none(), EAlreadyEquippedWeapon);

    // Equip weapon
    hero.weapon.fill(weapon);
}


// Tests

#[test]
fun test_mint() {
    let mut test = test_scenario::begin(@0xCAFE);

    let hero_name: String = utf8(b"SuperDimitrios");
    let hero = mint_hero(hero_name, 100, test.ctx());

    let obj_id = hero.id.to_inner();
    assert!(object::id(&hero) == obj_id, EInvalidHeroId);

    assert!(hero.name == hero_name, 0);

    destroy_for_testing(hero);
    test.end();
}

#[test]
fun test_equip() {
    let mut test = test_scenario::begin(@0xCAFE);
    
    // Create hero
    let hero_name = utf8(b"SuperDimitrios");
    let mut hero = mint_hero(hero_name, 100, test.ctx());
    
    // Create weapon
    let weapon_name = utf8(b"Frappedaki");
    let weapon = mint_weapon(weapon_name, 50, test.ctx());
    
    // Equip weapon to hero
    hero.equip_weapon(weapon);
    // alternative syntax:
    //equip_weapon(&mut hero, weapon);
    
    // Verify weapon is equipped
    assert!(hero.weapon.is_some(), EWeaponNotEquipped);
    let equipped_weapon = hero.weapon.borrow();
    assert!(equipped_weapon.name == weapon_name, EInvalidWeaponFields);
    assert!(equipped_weapon.power == 50, EInvalidWeaponFields);
    
    destroy_for_testing(hero);
    test.end();
}

#[test]
#[expected_failure(abort_code = EAlreadyEquippedWeapon)]
fun test_double_equip() {
    let mut test = test_scenario::begin(@0xCAFE);

    let mut hero = mint_hero(utf8(b"SuperDimitrios"), 100, test.ctx());

    let weapon1 = mint_weapon(utf8(b"Frappedaki"), 50, test.ctx());

    hero.equip_weapon(weapon1);
    assert!(hero.weapon.is_some(), EWeaponNotEquipped);

    // Try to equip weapon again
    let weapon2 = mint_weapon(utf8(b"Freddo"), 60, test.ctx());
    hero.equip_weapon(weapon2);

    destroy_for_testing(hero);
    test.end();
}


// Tests helper functions

#[test_only]
fun destroy_for_testing(hero : Hero){
    // See https://github.com/sui-foundation/sui-move-intro-course/blob/main/unit-two/lessons/3_parameter_passing_and_object_deletion.md

    // Unpack hero and get id
    let Hero {
        id : id,
        name: _,
        stamina: _,
        weapon : _w
    } = hero;
    // Delete hero
    object::delete(id);

    // Delete weapon if it exists
    if(_w.is_some()){
        let Weapon {
            id: wid,
            name: _,
            power: _
        }  = _w.destroy_some();
        object::delete(wid);    
    }
    else{
        _w.destroy_none();
    }
}