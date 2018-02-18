class Settings{
    
    JSONObject settings;

    public Settings(String path){
        settings = loadJSONObject(path);
    }

    public ArrayList<PVector> getPerspectiveSettings(){
        JSONObject cameraSettings = settings.getJSONObject("camera");
        JSONArray perspectiveSettings = cameraSettings.getJSONArray("perspective");

        ArrayList<PVector> perspective = new ArrayList<PVector>();
        for(int i = 0; i < 4; i++){
            JSONObject vertex = perspectiveSettings.getJSONObject(i);
            perspective.add(new PVector(vertex.getInt("x"), vertex.getInt("y")));
        }

        return perspective;
    }
}