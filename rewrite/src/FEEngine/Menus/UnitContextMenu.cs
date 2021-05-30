﻿using System;
using System.Collections.Generic;
using FEEngine.Math;

namespace FEEngine.Menus
{
    /// <summary>
    /// A menu for controlling <see cref="Unit"/>s
    /// </summary>
    public class UnitContextMenu : IRenderable
    {
        /// <summary>
        /// A page of a <see cref="UnitContextMenu"/>
        /// </summary>
        public abstract class Page
        {
            public Page()
            {
                mChildren = new();
                mCurrentChildIndex = -1;
                mCurrentSelection = 0;
                CanGoBack = true;
            }
            public void Update()
            {
                UpdatePage();
                if (mCurrentSelection >= mChildren.Count)
                {
                    mCurrentSelection = mChildren.Count - 1;
                }
                InputManager.State state = InputManager.GetState();
                if (state.Up && mCurrentSelection > 0)
                {
                    mCurrentSelection--;
                }
                if (state.Down && mCurrentSelection < mChildren.Count - 1)
                {
                    mCurrentSelection++;
                }
                if (state.OK)
                {
                    mCurrentChildIndex = mCurrentSelection;
                    mChildren[mCurrentChildIndex].OnSelect();
                }
                if (state.Back && CanGoBack)
                {
                    Parent.mCurrentChildIndex = -1;
                }
                if (mCurrentChildIndex != -1)
                {
                    mChildren[mCurrentChildIndex].Update();
                }
            }
            public void Render(RenderContext context)
            {
                if (mCurrentChildIndex == -1)
                {
                    RenderPage(context);
                }
                else
                {
                    mChildren[mCurrentChildIndex].Render(context);
                }
            }
            private void RenderPage(RenderContext context)
            {
                for (int i = 0; i < mChildren.Count; i++)
                {
                    IVec2<int> position = new Vec2I(3, (i * 2) + 1);
                    if (mCurrentSelection == i)
                    {
                        context.RenderChar(MathUtil.SubVectors(position, new Vec2I(2, 0)), '>', Color.Red);
                    }
                    context.RenderString(position, mChildren[i].GetTitle());
                }
            }
            public bool AddChild(Page page)
            {
                if (mChildren.Count >= 5)
                {
                    return false;
                }
                page.Parent = this;
                mChildren.Add(page);
                return true;
            }
            protected virtual void OnSelect() { }
            protected virtual void UpdatePage() { }
            protected abstract string GetTitle();
            private int mCurrentChildIndex, mCurrentSelection;
            private readonly List<Page> mChildren;
            protected Page Parent { get; private set; }
            protected List<Page> Children { get => mChildren; }
            protected bool CanGoBack { get; set; }
            internal virtual bool IsInternal { get { return false; } }
        }
        private class WaitPage : Page
        {
            protected override string GetTitle()
            {
                return "Wait";
            }
            protected override void OnSelect()
            {
                UIController.SelectedUnit.Wait();
                UIController.ResetSelectedUnit();
                UIController.IsUnitContextMenuOpen = false;
            }
        }
        private class BasePage : Page
        {
            public BasePage(UnitContextMenu parent)
            {
                CanGoBack = false;
                mParent = parent;
            }
            protected override void UpdatePage()
            {
                RefreshMenuItems();
                InputManager.State state = InputManager.GetState();
                if (state.Back)
                {
                    UIController.SelectedUnit.Move(mParent.OriginalUnitPosition, Unit.MovementType.RefundMovement);
                    mParent.OriginalUnitPosition = null;
                    UIController.IsUnitContextMenuOpen = false;
                }
            }
            private void RefreshMenuItems()
            {
                bool goAgain = true;
                while (goAgain)
                {
                    goAgain = false;
                    foreach (Page page in Children)
                    {
                        if (page.IsInternal)
                        {
                            goAgain = true;
                            Children.Remove(page);
                            break; // to stop the enumerator from throwing an exception
                        }
                    }
                }
                // todo: run calculations for pages: attack, item, etc.
                Children.Add(new WaitPage());
            }
            private readonly UnitContextMenu mParent;
            protected override string GetTitle()
            {
                throw new NotImplementedException(); // noones gonna call this anyway
            }
        }
        public IVec2<int> MinSize { get { return new Vec2I(10, 20); } }
        public UnitContextMenu()
        {
            OriginalUnitPosition = null;
            mBasePage = new BasePage(this);
        }
        public void Update()
        {
            mBasePage.Update();
        }
        public void Render(RenderContext context)
        {
            if (mRenderSize.X < MinSize.X || mRenderSize.Y < MinSize.Y)
            {
                return;
            }
            int xDifference = mRenderSize.X - MinSize.X;
            if (xDifference % 2 > 0)
            {
                xDifference--;
            }
            int padding = xDifference / 2;
            context.PushPair(new RenderContext.OffsetClipPair()
            {
                Offset = new Vec2I(padding, 0),
                Clip = MathUtil.SubVectors(mRenderSize, new Vec2I(padding, 0))
            });
            mBasePage.Render(context);
            context.PopPair();
        }
        public bool AddPage(Page page)
        {
            return mBasePage.AddChild(page);
        }
        public void SetSize(IVec2<int> size)
        {
            mRenderSize = size;
        }
        public IVec2<int> OriginalUnitPosition { private get; set; }
        private IVec2<int> mRenderSize;
        private readonly Page mBasePage;
    }
}