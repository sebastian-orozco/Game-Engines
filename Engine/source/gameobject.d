// @file: full_component/gameobject.d
import core.atomic;
import std.stdio, std.conv, std.json;

import component;
import script;
import factory;

/// Represents a single object in the game world.
/// Each GameObject has a name, ID, a set of components, and attached scripts.
class GameObject{

		/// Global map of GameObjects by name.
		static GameObject[string] sGameObjects;
		
		/// Reverse map of GameObject IDs to names.
		static string[size_t] sGameObjectsNameToID;

		/// Retrieves a GameObject by name.
		static GameObject GetGameObject(string name){
				if(name in sGameObjects){
						return sGameObjects[name];
				}
				return null;
		}   

		/// Retrieves a GameObject by ID.
		static GameObject GetGameObject(size_t id){
				if(id in sGameObjectsNameToID){
						return sGameObjects[sGameObjectsNameToID[id]];
				}
				return null;
		}   

		/// Constructs a new GameObject with a unique ID and name.
		this(string name){
				assert(name.length > 0);
				mName = name;	
				// atomic increment of number of game objects
				sGameObjectCount.atomicOp!"+="(1);		
				mID = sGameObjectCount; 

				// Store game object
				sGameObjects[name] = this;
				// Store ID to GameObject
				sGameObjectsNameToID[mID] = name;
		}

		// Destructor
		~this(){	}


		/// Loads components and scripts for this object from a JSON value.
		void loadFromJSON(JSONValue j) {
			import std.algorithm, std.array;

			foreach(compName, compJSON ; j["components"].object) {
				mComponents[to!ComponentType(compName)] = ComponentFactory.GetInstance().CreateComponent(compName, mID);
				mComponents[to!ComponentType(compName)].loadFromJSON(compJSON);
			}
			// Handle component dependencies
			if (ComponentType.ANIMATEDTEXTURE in mComponents) {
				auto animated = cast(ComponentAnimatedTexture)mComponents[ComponentType.ANIMATEDTEXTURE];
				if (animated.mFilename.length > 0) {
					animated.SetTexture(animated.mFilename);
				}
			}

			mScripts = j["scripts"].array.map!(s => ScriptFactory.GetInstance().CreateScript(s.str, mID, null)).array;
		}

		/// Serializes the object to JSON, including components and scripts.
		JSONValue toJSON() {
			import std.algorithm, std.array;
			string[] scripts = mScripts.map!(s => s.GetName()).array;
			JSONValue[string] components;
			foreach(c ; mComponents) {
				components[c.GetName()] = c.toJSON(); // Write this for each component
			}
			JSONValue j = ["scripts": scripts];
			j.object["components"] = components;
			j.object["name"] = mName;
			return j;
		}

		/// Returns the name of the object.
		string GetName() const { return mName; }

		/// Returns the ID of the object.
		size_t GetID() const { return mID; }

		/// Updates this object (empty by default, overridden elsewhere).
		void Update(){

		}

		/// Retrieves a component by its type.
		// NOTE: This could be 'templated' to avoid passing a
		//       parameter into the function.
		IComponent GetComponent(ComponentType type){
				if(type in mComponents){
						return mComponents[type];
				}else{
						return null;
				}
		}

		/// Adds a component to the object under a specific type key.
		void AddComponent(ComponentType T)(IComponent component){
				mComponents[T] = component;
		}

		/// List of scripts attached to the object.
		IScript[] mScripts;

		// Common components for all game objects
		// Pointers are 'null' by default in DLang.
		// See reference types: https://dlang.org/spec/property.html#init
		/// Map of components by type.
		IComponent[ComponentType] 	mComponents;

		private:
		// Any private fields that make up the game object
		string mName;
		size_t mID;

		static shared size_t sGameObjectCount = 0;
}
