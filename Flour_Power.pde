// Title: Flour Power
// Programmer: Michelle Ma
// Last Modified: 11 March 2021
// Description: A simulator designed to recreate the chemical reactions between
//     yeast, sugar, and carbon dioxide gas during the rising and baking of bread.
//     Protip: During the rising stage, click to stir/knead the dough :)

// changable values
int numColumns = 100; //number of cells across the screen
int amountSugar = 20; //compared to 100 parts of dough
int amountYeast = 10; 
int amountSalt = 1;
float roomTemp = 25; //celsius
float ovenTemp = 450; //fahrenheit
int risingTime = 40;
int bakingTime = 60;
boolean displayStats = true;
int blinksPerSecond = 5;

//don't change these values
int numRows = numColumns;
float startingHeight, cellWidth;
int startingRows, numCells;
int amountDough = 100;
int totalRatio = amountDough+amountSugar+amountYeast+amountSalt;
String state = "rising";

String[] ratios = new String[totalRatio];
int[] topRow = new int[numColumns];
color[][] finalValues;
color[][] nextValues;
int numCO2Patches = 0;
int[][] CO2Patches;

int doughRed = 242;
int doughGreen = 220;
int doughBlue = 155;
color doughCol;
color yeastCol = color(160,82,45);
color CO2Col = color(255, 253, 112);
color sugarCol = color(255);
color saltCol = color(173, 216, 230);
color backgroundCol = color(0, 0, 128);

void initialValues(){ // fills arrays and sets starting values
  doughCol = color(doughRed,doughGreen,doughBlue);
  for(int i=0;i<totalRatio;i++){
    if(i<=amountDough)
      ratios[i] = "dough";
    else if(i<=amountDough+amountSugar)
      ratios[i] = "sugar";
    else if(i<=amountDough+amountSugar+amountSalt)
      ratios[i] = "salt";
    else
      ratios[i] = "yeast";
  }
  for(int i=0;i<numRows;i++){
    for(int a=0;a<numColumns;a++){
      if(i<=startingRows){
        String choice = ratios[round(random(0, totalRatio-1))];
        if(choice == "dough")
          finalValues[i][a] = doughCol;
        else if(choice == "sugar")
          finalValues[i][a] = sugarCol;
        else if(choice == "salt")
          finalValues[i][a] = saltCol;
        else
          finalValues[i][a] = yeastCol;
      }
      else
        finalValues[i][a] = backgroundCol;
    }
  }
}

void drawState(){ // draws the cells onto the screen
  float yVal = height-cellWidth;
  for(int i=0;i<numRows;i++){
    float xVal = 0;
    for(int j=0;j<numColumns;j++){
      fill(finalValues[i][j]);
      stroke(finalValues[i][j]);
      square(xVal, yVal, cellWidth);
      xVal += cellWidth;
    }
   yVal -= cellWidth;
  }
}

void setup(){
  size(600, 600);
  frameRate(blinksPerSecond);
  startingRows = int(numColumns/3);
  for(int x=0;x<topRow.length;x++){
    topRow[x] = startingRows;
  }
  cellWidth = float(width)/numColumns;
  numCells = numRows*numColumns; 
  finalValues = new color[numRows][numColumns];
  nextValues = new color[numRows][numColumns];
  CO2Patches = new int[numRows][numColumns];
  initialValues();
  drawState();
}

void draw(){
  drawState();
  nextGen();
  update();
  if(displayStats == true)
    showStats();
  if(frameCount == risingTime){
    clearDough();
    update();
    patchLoop();
  }
  else if(frameCount == 1 + risingTime)
    state = "baking";
  if(frameCount > 1+risingTime){
    float check = random(0, 500);
      if(ovenTemp>= check)
        darkenBread(); // darkens at a speed depending on the oven temperature
  }
  
  if((state == "baking") && (frameCount-risingTime >= bakingTime)){ // displays ending text
    stop();
    textSize(18);
    textAlign(CENTER);
    fill(255);
    int quality = calculateQuality();
    text("Bread is finished. Yum.", width/2, 130);
    text("Quality = " + str(quality) + " stars out of five", width/2, 150);
    drawStars(quality);
  }
}

void drawStars(int x){
  String starCode;
  float starX = 260;
  for(int a=1;a<=5;a++){
    if(a<=x)
      starCode = "\u272a";
    else
      starCode = "\u2605";
    textSize(17);
    text(starCode, starX, 175);
    starX += 20;
  }
}

void showStats(){ // statistics box text
  String stats = "";
  if(state == "rising"){
    stats = "Current stage: Rising";
    stats += "\nRoom temperature = " + str(roomTemp) + "\u00b0C";
    stats += "\nRising time elapsed = " + str(frameCount) + " minutes";
  }
  else if(state == "baking"){
    stats = "Current stage: Baking";
    stats += "\nOven temperature = " + str(ovenTemp) + "\u00b0F";
    stats += "\nBaking time elapsed = " + str(frameCount-risingTime) + " minutes";
    fill(255);
    rect(15, 75, 250, 15);
    fill(255,215,0);
    rect(15, 75, abs(250-calculateBurntLevel()*25), 15);
    fill(255);
    text("Level of Toastiness: " + str(abs(10-calculateBurntLevel())), 20, 110);
  }
  textSize(14);
  fill(255);
  text(stats, 10, 20);
}

int calculateBurntLevel(){ // determines burnt level based on amount of red colour
  float red = red(doughCol);
  int burntLevel = 10;
  for(int x = 230; x>=130; x-=10){
    if(red>=x)
      return burntLevel;
    burntLevel--;
  } 
  return 0;
}

int calculateQuality(){ // calculates quality of bread based on burnt level
  int level = calculateBurntLevel();
  int nearPerfect = abs(5-level);
  return 5-nearPerfect;
}

void nextGen(){ // determines next generation of cells
  for(int i=0;i<numRows;i++){
    for(int a=0;a<numColumns;a++){
      if(state == "rising"){
        if(finalValues[i][a] == yeastCol){
          lookForSugar(i, a);
          lookForSalt(i, a);
        }
      }
      else if(state == "baking"){
        if(finalValues[i][a] == CO2Col)
          growCO2(i, a);
        }
      }
    }
  for(int i=0;i<numRows;i++){ // fills all dough values left
    for(int a=0;a<numColumns;a++){
      if(nextValues[i][a] == 0)
        nextValues[i][a] = finalValues[i][a];
    }
  }
}

void update(){ // replaces final cell values
  for(int i=0;i<numRows;i++){
    for(int a=0;a<numColumns;a++){
      finalValues[i][a] = nextValues[i][a];
    }
  }
}

void lookForSugar(int x, int i){
  float yeastRange = 10*abs(24-roomTemp);
  float range = 1000-yeastRange;
  float p = random(0, 1000);
  for(int a=-1;a<=1;a++){
    for(int b=-1;b<=1;b++){
      try{
        color value = finalValues[x+a][i+b];
        if((a!=0 || b!=0) && (value == sugarCol)){
          if(p<=range){ // only works occasionally depending on roomTemp
            nextValues[x+a][i+b] = yeastCol; // yeast cell moves to sugar cell
            nextValues[x][i] = doughCol;
            generateCO2(x+a, i+b);
            }
          break; // breaks loop no matter if yeast "ate" sugar or not
        }
      }
      catch(Exception e){
      }
    }
  }
}

void lookForSalt(int x, int i){
  for(int a=-1;a<=1;a++){
    for(int b=-1;b<=1;b++){
      try{
        color value = finalValues[x+a][i+b];
        if((a!=0 || b!=0) && (value == saltCol)){
          nextValues[x][i] = doughCol; // the yeast is "killed"
        }
      }
      catch(Exception e){
      }
    }
  }
}

void generateCO2(int a, int b){
  int row = 0;
  int column = 0;
  try{
    while(row==0 && column==0){ // ensures it goesn't choose itself
      row = round(random(-1, 1));
      column = round(random(-1, 1)); 
    }
    nextValues[a+row][b+column] = CO2Col;
    doughRise(b+column);
  }
  catch(Exception e){
  }
}

void doughRise(int x){
  nextValues[topRow[x]+1][x] = doughCol;
  topRow[x] += 1;
}

void growCO2(int x, int y){
  float p = random(0, 200);
  float tempVar = ovenTemp/100; //number preferably from 1 to 10
  if(p<=tempVar){ //only grows sometimes
    for(int a=-1;a<=1;a++){
      for(int b=-1;b<=1;b++){
        try{
          if((a!=0 || b!=0) && (finalValues[x+a][y+b] == doughCol)){
            if(notTouchingAnotherPatch(x, y, x+a, y+b)){
              nextValues[x+a][y+b] = CO2Col;
              CO2Patches[x+a][y+b] = CO2Patches[x][y]; //adds grown CO2 to patch
              doughRise(y+b);
              break;
            }
          }
        }
        catch(Exception e){
        }
      }
    }
  }
}

void patchLoop(){ // counts and assigns patches of CO2
  for(int i=0;i<numRows;i++){
    for(int a=0;a<numColumns;a++){
      if((finalValues[i][a] == CO2Col) && (CO2Patches[i][a] == 0)){ //when an unassigned patch is found
        numCO2Patches++;
        CO2Patches[i][a] = numCO2Patches;
        assignLoop(i, a);
      }
    }
  }
}

void assignLoop(int x, int y){
  CO2Patches[x][y] = numCO2Patches;
  for(int a=-1;a<=1;a++){
    for(int b=-1;b<=1;b++){
      try{
        if((a!=0||b!=0) && (finalValues[x+a][y+b] == CO2Col) && (CO2Patches[x+a][y+b] == 0)){
          assignLoop(x+a, y+b); // recursion... recheck and assign around that cell
        }
      }
      catch(Exception e){
      }
    }
  }
}

boolean notTouchingAnotherPatch(int orgX, int orgY, int x, int y){ // check if one patch is touching another
  for(int a=-1;a<=1;a++){
    for(int b=-1;b<=1;b++){
        try{
          if((a!=0||b!=0) && (finalValues[x+a][y+b] == CO2Col) && (CO2Patches[x+a][y+b] != CO2Patches[orgX][orgY])){ 
            return false; 
          }
        }
      catch(Exception e){
      }
    }
  }
  return true;
}

void clearDough(){ // replaces all sugar and yeast cells with dough cells
  for(int i=0;i<numRows;i++){
    for(int a=0;a<numColumns;a++){
      if((finalValues[i][a] == sugarCol) || (finalValues[i][a] == yeastCol) || (finalValues[i][a] == saltCol))
        nextValues[i][a] = doughCol;
    }
  }
}

void mouseClicked(){ // moves the yeast if the mouse clicks
  if(state=="rising"){
    for(int x=0;x<numRows;x++){
      for(int y=0;y<numColumns;y++){
        if(finalValues[x][y] == sugarCol || finalValues[x][y] == saltCol || finalValues[x][y] == yeastCol){ // if it's salt, sugar, or yeast
          int m = round(random(-1, 1));
          int n = round(random(-1, 1));
          try{
            if((m!=0||n!=0) && (finalValues[x+m][y+n] == doughCol)){
              nextValues[x][y] = doughCol;
              nextValues[x+m][y+n] = finalValues[x][y];
              update();
            }
          }
          catch(Exception e){
          }
        }
      }
    }
  }
}

void darkenBread(){ // darkens the dough
  doughRed -= 1;
  doughGreen -= 1;
  doughBlue -= 1;
  color newDoughCol = color(doughRed,doughGreen,doughBlue);
  for(int i=0;i<numRows;i++){
    for(int a=0;a<numColumns;a++){
      if(finalValues[i][a] == doughCol)
        nextValues[i][a] = newDoughCol;
    }
  }
  doughCol = newDoughCol;
  update();
}
