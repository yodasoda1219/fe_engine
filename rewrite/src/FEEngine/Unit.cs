﻿using System;
using Newtonsoft.Json;
using Newtonsoft.Json.Converters;
using FEEngine.Math;
using FEEngine.Scripting;

namespace FEEngine
{
    [JsonObject]
    public class Unit : RegistedObjectTemplate<Unit>
    {
        public enum UnitAffiliation
        {
            Player,
            Enemy,
            ThirdEnemy,
            Ally
        }
        public enum MovementType
        {
            ConsumeMovement,
            IgnoreMovement,
            RefundMovement
        }
        [JsonObject]
        public struct UnitStats
        {
            public int HP, Str, Mag, Dex, Spd, Lck, Def, Res, Cha, Mv;
        }
        public string Name { get; set; }
        public UnitStats Stats { get; set; }
        public IVec2<int> Position { get; private set; }
        [JsonIgnore]
        public int CurrentMovement { get; private set; }
        [JsonIgnore]
        public bool CanMove { get; private set; }
        [JsonIgnore]
        public int CurrentHP { get; private set; }
        [JsonConverter(typeof(StringEnumConverter))]
        public UnitAffiliation Affiliation { get; set; }
        [JsonIgnore]
        public Map Parent { get; set; }
        public void AttachBehavior<B>(B behavior) where B : IUnitBehavior, new()
        {
            mBehavior = behavior;
            if (mBehavior == null)
            {
                BehaviorName = null;
            }
            else
            {
                mBehavior.Parent = this;
                BehaviorName = typeof(B).Name;
            }
        }
        public B GetBehavior<B>() where B : IUnitBehavior, new()
        {
            return (B)mBehavior;
        }
        public void RefreshMovement()
        {
            CurrentMovement = Stats.Mv;
            CanMove = true;
        }
        public string BehaviorName { get; set; }
        [JsonConstructor]
        public Unit(IVec2<int> position, UnitAffiliation affiliation, UnitStats stats, string behaviorName = null, string name = "Soldier")
        {
            Name = name;
            Position = position;
            Affiliation = affiliation;
            Stats = stats;
            BehaviorName = behaviorName;
            RefreshMovement();
            CurrentHP = Stats.HP;
            if (BehaviorName == null)
            {
                mBehavior = null;
            } 
            else
            {
                // i couldnt think of any other way lmaoooo
                Type behaviorType = Type.GetType(BehaviorName);
                if (behaviorType == null)
                {
                    mBehavior = null;
                    return;
                }
                var constructor = behaviorType.GetConstructor(new Type[0]);
                mBehavior = (IUnitBehavior)constructor.Invoke(new object[0]);
            }
        }
        private IUnitBehavior mBehavior;
    }
}