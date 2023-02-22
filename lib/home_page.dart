import 'dart:async';

import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:snake_game_flutter/blank_pixel.dart';
import 'package:snake_game_flutter/food_pixel.dart';
import 'package:snake_game_flutter/highscore_tile.dart';
import 'package:snake_game_flutter/snake_pixel.dart';



class HomePage extends StatefulWidget {
  const HomePage({super.key});


  @override
  State<HomePage> createState() => _HomePageState();
}

enum snake_Direction{UP,DOWN,LEFT,RIGHT}

class _HomePageState extends State<HomePage> {

//grid dimensions
int rowSize=10;
int totalSquares=100;
int currentScore=0;

bool gameHasStarted=false;

//game settings
final _nameController=TextEditingController();

//snake position
List<int> snakePos=[0,1,2];

//snake direction initially to the right
var currentDirection=snake_Direction.RIGHT;

//food location
int foodpos=55;

//highscore list
List<String> highscore_DocIds=[];
late final Future? letsGetDocIds;

@override
  void initState() {
 letsGetDocIds=getDocId();
    super.initState();
  }

Future getDocId()async{
await FirebaseFirestore.instance.collection('highscores').
orderBy('score',descending: true).limit(10).get().then((value) => value.docs.forEach((element) {
  highscore_DocIds.add(element.reference.id);
}));
}

//start game method
void startGame(){
  gameHasStarted=true;
  Timer.periodic(Duration(milliseconds: 200), (timer) { 
   setState(() {
    //make sure the snake is moving
   moveSnake();
     
     //check if gameis over
     if(gameOver()){
      timer.cancel();
      //display the message to the user
      showDialog(
      context: context, 
      barrierDismissible: false,
      builder: (context){
        return AlertDialog(
          title: Text("Game Over"),
          content: Column(
            children: [
              Text("Your score is:"+currentScore.toString()),
              TextField(
                controller: _nameController,
                decoration: InputDecoration(hintText: 'Enter Name: '),
              ),
            ],
          ),
          actions: [MaterialButton(
            onPressed: (){
               Navigator.pop(context);
              submitScore();
              newGame();
            },
            child: Text('Submit Score'),
            color: Colors.pink,
            )],
        );
      });
     }
   });
  });
}
void submitScore(){
//get access to the collection
var database=FirebaseFirestore.instance;
//add data to firebase
database.collection('highscores').add({
  "name": _nameController.text,
  "score": currentScore,
});


}
Future newGame()async{
  highscore_DocIds=[];
  await getDocId();
  setState(() {
    snakePos=[0,1,2];
    foodpos=55;
    currentDirection=snake_Direction.RIGHT;
    gameHasStarted=false;
    currentScore=0;
  });
}

void eatFood(){
  currentScore++;
while (snakePos.contains(foodpos)) {
  foodpos=Random().nextInt(totalSquares);
}
}

void moveSnake(){
  switch (currentDirection) {
    case snake_Direction.RIGHT:
      {

        //if snake is at the right wall, it needs to re-adjust
        if(snakePos.last%rowSize==9){
           snakePos.add(snakePos.last+1-rowSize);
        }else{
           snakePos.add(snakePos.last+1);
        }
       
       
      }
      break;
      case snake_Direction.LEFT:
      {
        //if snake is at the left wall, it needs to re-adjust
        if(snakePos.last%rowSize==0){
           snakePos.add(snakePos.last-1+rowSize);
        }else{
           snakePos.add(snakePos.last-1);
        }
       
  
      }
      break;
      case snake_Direction.UP:
      {
        if(snakePos.last<rowSize){
           snakePos.add(snakePos.last-rowSize+totalSquares);
        }else{
           snakePos.add(snakePos.last-rowSize);
        }       
        
      }
      break;
      case snake_Direction.DOWN:
      {
          if(snakePos.last+rowSize>totalSquares){
           snakePos.add(snakePos.last+rowSize-totalSquares);
        }else{
           snakePos.add(snakePos.last+rowSize);
        } 

     
      }
      break;
    default:
  }
  if(snakePos.last==foodpos){
      eatFood();
  }else{
      snakePos.removeAt(0);
  }

}
 //game over
 bool gameOver(){
  //the game is over when the snake runs into itself
  //this occurs when there is duplicate position in snakePos list

  //this list is the body of the snake(with no head)
  List<int>bodySnake=snakePos.sublist(0,snakePos.length-1);

  if(bodySnake.contains(snakePos.last)){
    return true;
  }
  return false;

}

  @override
  Widget build(BuildContext context) {

    //get the screen width
    double screenWidth=MediaQuery.of(context).size.width;

    return Scaffold(
      backgroundColor: Colors.black,
      body:SizedBox(
      
        child: Column(
          children: [
            //hight scores
            Expanded(
              
            child: Row(
            
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text('Current Score'),
                  //user current score
                  Text(currentScore.toString(),style: TextStyle(fontSize: 36),),
                  //
                             
                               
                    ],
                  ),
                ),
                  SizedBox(
                    width: 20.0,
                  ), //high score top5 or 10 
                   Expanded(
                     child: gameHasStarted ? Container():FutureBuilder(
                      future: letsGetDocIds,
                      builder: (context,snapshot){
                      return ListView.builder(
                        itemCount: highscore_DocIds.length,
                        itemBuilder:((context,index){
                        return HighScoreTile( documentId: highscore_DocIds[index]);
                      }));
                     }),
                   )
                
              ],
            ),
            ),
      
            //game grid
            Expanded(
              flex: 3,
              child: GestureDetector(
                onVerticalDragUpdate: (details) {
                  if(details.delta.dy>0&&currentDirection!=snake_Direction.UP){
                    currentDirection=snake_Direction.DOWN;
                  }else if(details.delta.dy<0&&currentDirection!=snake_Direction.DOWN){
                  currentDirection=snake_Direction.UP;
                  }
                },
                onHorizontalDragUpdate: (details) {
                   if(details.delta.dx>0&&currentDirection!=snake_Direction.LEFT){
                    currentDirection=snake_Direction.RIGHT;
                  }else if(details.delta.dx<0!=snake_Direction.RIGHT){
                    currentDirection=snake_Direction.LEFT;
                  }
                },
                child: GridView.builder(
                  itemCount:totalSquares,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate:SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: rowSize),
                   itemBuilder: (context,index){
                    if(snakePos.contains(index)){
                      return SnakePixel();
                    }else if(foodpos==index){
                      return FoodPixel();
                    }
                    else{
                      return BlankPixel();
                    }
                   }
                   ),
              ),
              ),
      
            //play button
            Expanded(
            child: Container(
              child: Center(
                child: MaterialButton(
                  color:gameHasStarted ?Colors.grey: Colors.pink,
                  child:  Text('PLAY'),
                  onPressed: gameHasStarted ?(){} : startGame,
                ),
              ),
            ),
            ),
          ],
        ),
      ),
    );
  }
}