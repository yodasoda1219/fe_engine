﻿namespace FEEngine
{
    public class Game
    {
        public Game()
        {
            InputManager.Init();
            mRegistry = new Registry();
        }
        public Registry Registry
        {
            get
            {
                return mRegistry;
            }
        }
        public void Loop(Player player)
        {
            while (true)
            {
                Update(player);
                if (InputManager.GetState().Quit)
                {
                    break;
                }
            }
        }
        private void Update(Player player)
        {
            InputManager.Update();
            player.Update();
        }
        public void SetupRegisters()
        {
            mRegistry.CreateRegister<Map>();
            mRegistry.CreateRegister<Unit>();
        }
        private Registry mRegistry;
    }
}