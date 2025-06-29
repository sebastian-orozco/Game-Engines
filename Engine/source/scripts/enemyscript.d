import std.stdio;

import linear;
import gameobject;
import component;
import scripts;
import std.math;

import bindbc.sdl;

/// Script that controls basic vertical movement for an enemy GameObject.
/// Enemy bounces between the top and bottom bounds of the map.
class EnemyScript : IScript{

		Vec2f mVel;

		/// Constructs an EnemyScript tied to a GameObject by ID.
    	/// Initializes velocity to move downward.
		this(size_t owner){
			mOwner = owner;
			mVel = Vec2f(0, 0.5);
		}

		/// Updates the enemy's vertical movement each frame.
    	/// Reverses direction upon hitting the top or bottom bounds.
		override void Update(){

				// Retrieve the game object
				GameObject go = GameObject.GetGameObject(mOwner);

				auto transform = cast(ComponentTransform)go.GetComponent(ComponentType.TRANSFORM);
                auto position = cast(ComponentCollision)go.GetComponent(ComponentType.COLLISION);
            
				float len = sqrt(mVel.x * mVel.x + mVel.y * mVel.y);
				if (len > 0.0f) {
					mVel.x /= len;
					mVel.y /= len;
				}

				// Get the world bounds from the "world" GameObject's collision box
				GameObject carpet = GameObject.GetGameObject("carpet");
				auto bounds = cast(ComponentCollision)carpet.GetComponent(ComponentType.COLLISION);
				int bounds_x = bounds.mRect.x;
				int bounds_y = bounds.mRect.y;
				int bounds_w = bounds.mRect.w;
				int bounds_h = bounds.mRect.h;
				int position_x = position.mRect.x;
				int position_y = position.mRect.y;
				int position_w = position.mRect.w;
				int position_h = position.mRect.h;

				// If player is at the top or bottom edge and accelerating further, stop this direction of movement
				if (position_y <= bounds_y && mVel.y < 0) {
					mVel.y = 0.5;
				}
				if (((position_y + position_h) >= (bounds_y + bounds_h)) && mVel.y > 0) {
					mVel.y = -0.5;
				}

				// Perform acceleration
				transform.Translate(mVel.x,mVel.y);

				if(position !is null){
					// writeln(obj.GetName()," - collision render");
					Vec2f pos = transform.mWorldMatrix.Frommat3GetTranslation();
					position.mRect.x = cast(int)pos.x;
					position.mRect.y = cast(int)pos.y;
				}

		}

		/// Returns the name of this script.
		override string GetName() {
			return "EnemyScript";
		}

		private:
		size_t mOwner;
}