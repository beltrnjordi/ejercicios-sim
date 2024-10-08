// Problem description: //<Flag simulation using meshes>//
// Deformable object simulation
import peasy.*;

// Display control:

PeasyCam _camera;   // Mouse-driven 3D camera

// Simulation and time control:

float _timeStep;              // Simulation time-step (s)
int _lastTimeDraw = 0;        // Last measure of time in draw() function (ms)
float _deltaTimeDraw = 0.0;   // Time between draw() calls (s)
float _simTime = 0.0;         // Simulated time (s)
float _elapsedTime = 0.0;     // Elapsed (real) time (s)

// Output control:

boolean _writeToFile = false;
PrintWriter _output;

// System variables:

DeformableObject flag1, flag2, flag3;     // Deformable object
SpringLayout _springLayout;               // Current spring layout

// Main code:

void settings()
{
   size(DISPLAY_SIZE_X, DISPLAY_SIZE_Y, P3D);
}

void setup()
{
   frameRate(DRAW_FREQ);
   _lastTimeDraw = millis();

   float aspect = float(DISPLAY_SIZE_X)/float(DISPLAY_SIZE_Y);
   perspective((FOV*PI)/180, aspect, NEAR, FAR);
   _camera = new PeasyCam(this, 0);
   _camera.rotateX(-PI/2);
   // _camera.rotateZ();
   _camera.lookAt(-7.5, 0, 100);
   _camera.setDistance(200);

   initSimulation();
}

void changeValues(){
   if(isWind)
      wind_direction.set(1,-0.5,0);
   else
      wind_direction.set(0,0,0);

   if(isGravity)
      gravity.set(0, 0, -G * PARTICLE_MASS);
   else
      gravity.set(0, 0, 0);
}

void stop()
{
   endSimulation();
}

void keyPressed()
{
   if (key == 'R' || key == 'r')
      initSimulation();

   if (key == 'D' || key == 'd')
      DRAW_MODE = !DRAW_MODE;

   if (key == 'W' || key == 'w')
      isWind = !isWind;
   
   if (key == 'G' || key == 'g')
      isGravity = !isGravity;
}

void initSimulation()
{
   if (_writeToFile)
   {
      _output = createWriter(FILE_NAME);
      writeToFile("t, n, Tsim");
   }

   _simTime = 0.0;
   _timeStep = TS*TIME_ACCEL;
   _elapsedTime = 0.0;

   flag1 = new DeformableObject(SpringLayout.STRUCTURAL, #F4B9B2, KE_STRUCTURAL, KD_STRUCTURAL);
   flag2 = new DeformableObject(SpringLayout.STRUCTURAL_AND_BEND, #DE6B48, KE_SHEAR, KD_SHEAR);
   flag3 = new DeformableObject(SpringLayout.STRUCTURAL_AND_SHEAR, #7DBBC3, KE_BEND, KD_BEND);
}

void restartSimulation(SpringLayout springLayout)
{
   _simTime = 0.0;
   _timeStep = TS*TIME_ACCEL;
   _elapsedTime = 0.0;
   _springLayout = springLayout;
}

void endSimulation()
{
   if (_writeToFile)
   {
      _output.flush();
      _output.close();
   }
}

void draw()
{
   int now = millis();
   _deltaTimeDraw = (now - _lastTimeDraw)/1000.0;
   _elapsedTime += _deltaTimeDraw;
   _lastTimeDraw = now;

   background(BACKGROUND_COLOR);
   changeValues();
   // drawStaticEnvironment();
   drawDynamicEnvironment();

   if (REAL_TIME)
   {
      float expectedSimulatedTime = TIME_ACCEL*_deltaTimeDraw;
      float expectedIterations = expectedSimulatedTime/_timeStep;
      int iterations = 0;

      for (; iterations < floor(expectedIterations); iterations++)
         updateSimulation();

      if ((expectedIterations - iterations) > random(0.0, 1.0))
      {
         updateSimulation();
         iterations++;
      }
   } 
   else
      updateSimulation();

   displayInfo();

   if (_writeToFile)
      writeToFile(_simTime + "," + flag1.getNumNodes() + ", 0");
}

void drawStaticEnvironment()
{
   noStroke();
   fill(255, 0, 0);
   box(1000.0, 1.0, 1.0);

   fill(0, 255, 0);
   box(1.0, 1000.0, 1.0);

   fill(0, 0, 255);
   box(1.0, 1.0, 1000.0);

   fill(255, 255, 255);
   sphere(1.0);
}

void drawDynamicEnvironment()
{
   stroke(10);
   line(-120, 0, 0, -120, 0, 100 + N_V*D_V);
   line(-30, 0, 0, -30, 0, 100 + N_V*D_V);
   line(60, 0, 0, 60, 0, 100 + N_V*D_V);

   line(0,0,0,wind_direction.x, wind_direction.y, wind_direction.z);

   pushMatrix();
   {
      translate(-120, 0, 100+ N_V*D_V);
      sphere(1);
   }
   popMatrix();

   pushMatrix();
   {
      translate(-30, 0, 100+ N_V*D_V);
      sphere(1);
   }
   popMatrix();

   pushMatrix();
   {
      translate(60, 0, 100+ N_V*D_V);
      sphere(1);      
   }
   popMatrix();

   pushMatrix();
   {
      translate(-120, 0, 100);
      
      flag1.render();
   }
   popMatrix();

   pushMatrix();
   {
      translate(-30, 0, 100);
      flag2.render();
   }
   popMatrix();

   pushMatrix();
   {
      translate(60, 0, 100);
      flag3.render();
   }
   popMatrix();
}

void updateSimulation()
{
   flag1.update(_timeStep);
   flag2.update(_timeStep);
   flag3.update(_timeStep);
   
   _simTime += _timeStep;
}

void writeToFile(String data)
{
   _output.println(data);
}

void displayInfo()
{
   pushMatrix();
   {
      camera();
      fill(0);
      textSize(20);

      text("Frame rate = " + 1.0/_deltaTimeDraw + " fps", width*0.025, height*0.05);
      text("Elapsed time = " + _elapsedTime + " s", width*0.025, height*0.075);
      text("Simulated time = " + _simTime + " s ", width*0.025, height*0.1);
      text("Available options: [R] to reset simulation, [D] to change the drawMode,", width*0.025, height*0.15);
      text("[W] to toggle wind, [G] to toggle gravity", width*0.025, height*0.175);
      text("Gravity state: " + isGravity + "  Wind state:" +  isWind + wind_direction, width*0.025, height*0.2);

      fill(flag1._color);
      text("Structure: " + flag1._springLayout, width*0.7, height*0.05);
      text("KE: " + flag1._ke + " KD: " + flag1._kd, width*0.7, height*0.075);

      fill(flag2._color);
      text("Structure: " + flag2._springLayout, width*0.7, height*0.1);
      text("KE: " + flag2._ke + " KD: " + flag2._kd, width*0.7, height*0.125);

      fill(flag3._color);
      text("Structure: " + flag3._springLayout, width*0.7, height*0.15);
      text("KE: " + flag3._ke + " KD: " + flag3._kd, width*0.7, height*0.175);
   }
   popMatrix();
}
