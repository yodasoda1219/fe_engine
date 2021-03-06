﻿namespace FEEngine
{
    /// <summary>
    /// An object for keeping track of the current phase (whose turn it is)
    /// </summary>
    public class PhaseManager
    {
        public Unit.UnitAffiliation CurrentPhase { get; private set; }
        public PhaseManager(Unit.UnitAffiliation initialPhase = Unit.UnitAffiliation.Player)
        {
            CurrentPhase = initialPhase;
        }
        public void CyclePhase(Map map)
        {
            // i apologize for the spaghetti code
            switch (CurrentPhase)
            {
                case Unit.UnitAffiliation.Player:
                    CurrentPhase = Unit.UnitAffiliation.Enemy;
                    break;
                case Unit.UnitAffiliation.Enemy:
                    CurrentPhase = Unit.UnitAffiliation.ThirdEnemy;
                    break;
                case Unit.UnitAffiliation.ThirdEnemy:
                    CurrentPhase = Unit.UnitAffiliation.Ally;
                    break;
                case Unit.UnitAffiliation.Ally:
                    CurrentPhase = Unit.UnitAffiliation.Player;
                    break;
            }
            string phaseName = CurrentPhase.ToString();
            if (CurrentPhase == Unit.UnitAffiliation.ThirdEnemy)
            {
                phaseName = "Enemy"; // i am so sorry
            }
            Logger.Print(Unit.GetColorForAffiliation(CurrentPhase), "{0} phase", phaseName);
            var units = map.GetAllUnitsOfAffiliation(CurrentPhase);
            foreach (Unit unit in units)
            {
                unit.RefreshMovement();
            }
        }
    }
}
