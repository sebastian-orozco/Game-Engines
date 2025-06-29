/// Run with: 'dub'
import gameapplication;
import factory;
import script, playerscript, asteroids, cutscenescript, enemyscript, scenescript, winscript, losescript, menuscript;
import component;

// Entry point to program
void main() {
	// Register script factories
    ScriptFactory.GetInstance.RegisterScriptFactory("EnemyScript", (size_t oOwner, Scene* sOwner) => new EnemyScript(oOwner));
	ScriptFactory.GetInstance.RegisterScriptFactory("PlayerScript", (size_t oOwner, Scene* sOwner) => new PlayerScript(oOwner));
	ScriptFactory.GetInstance.RegisterScriptFactory("CutsceneScript", (size_t oOwner, Scene* sOwner) => new CutsceneScript(sOwner));
	ScriptFactory.GetInstance.RegisterScriptFactory("WinScreenScript", (size_t oOwner, Scene* sOwner) => new WinScreenScript(sOwner));
	ScriptFactory.GetInstance.RegisterScriptFactory("LoseScreenScript", (size_t oOwner, Scene* sOwner) => new LoseScreenScript(sOwner));
	ScriptFactory.GetInstance.RegisterScriptFactory("MenuScript", (size_t oOwner, Scene* sOwner) => new MenuScript(sOwner));
	ScriptFactory.GetInstance.RegisterScriptFactory("GameScript", (size_t oOwner, Scene* sOwner) => new GameScript(sOwner));
	// Register component factories
	ComponentFactory.GetInstance.RegisterComponentFactory("TEXTURE", (size_t owner) => new ComponentTexture(owner));
	ComponentFactory.GetInstance.RegisterComponentFactory("TRANSFORM", (size_t owner) => new ComponentTransform(owner));
	ComponentFactory.GetInstance.RegisterComponentFactory("COLLISION", (size_t owner) => new ComponentCollision(owner));
	ComponentFactory.GetInstance.RegisterComponentFactory("ANIMATEDTEXTURE", (size_t owner) => new ComponentAnimatedTexture(owner));
	ComponentFactory.GetInstance.RegisterComponentFactory("TEXT", (size_t owner) => new ComponentText(owner));

	GameApplication app = GameApplication("Nightmare At The Museum");
	app.RunLoop();
}
