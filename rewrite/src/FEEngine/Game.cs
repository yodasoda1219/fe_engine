﻿using System.IO;
using System.Runtime.CompilerServices;

namespace FEEngine
{
    public class Game
    {
        public static bool Debug
        {
            get => debug;
            set => debug = value;
        }
        public static bool HasNativeImplementation
        {
            get => hasNativeImplementation;
            set => hasNativeImplementation = value;
        }
        public static void BreakDebugger()
        {
            if (Debug && HasNativeImplementation)
            {
                BreakDebugger_Native();
            }
        }
        public int CurrentMapIndex { get; set; }
        public Game(string bindingsFile = null)
        {
            CurrentMapIndex = 0;
            mKeyBindingsFile = bindingsFile;
            mRegistry = new Registry();
            if (mKeyBindingsFile != null)
            {
                if (File.Exists(mKeyBindingsFile))
                {
                    InputManager.ReadBindings(mKeyBindingsFile);
                }
            }
        }
        ~Game()
        {
            if (mKeyBindingsFile != null)
            {
                InputManager.WriteBindings(mKeyBindingsFile);
            }
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
                Render(player);
            }
        }
        private void Update(Player player)
        {
            InputManager.Update();
            player.Update();
        }
        private void Render(Player player)
        {
            Renderer.ClearBuffer();
            RenderQueue renderQueue = new();
            // render order
            // 1. map
            Map map = mRegistry.GetRegister<Map>()[CurrentMapIndex];
            renderQueue.Submit(map);
            // 2. player (cursor)
            renderQueue.Submit(player);

            renderQueue.Close();
            Renderer.Render(renderQueue);
        }
        public void SetupRegisters()
        {
            mRegistry.CreateRegister<Map>();
            mRegistry.CreateRegister<Unit>();
            mRegistry.CreateRegister<Item>();
        }
        private Registry mRegistry;
        private string mKeyBindingsFile;
        private static bool debug = false;
        private static bool hasNativeImplementation = true;
        // native methods
        [MethodImpl(MethodImplOptions.InternalCall)]
        private static extern void BreakDebugger_Native();
    }
}
