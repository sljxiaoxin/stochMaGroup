//+------------------------------------------------------------------+
//|     基于stoch + 20MA
//
//+------------------------------------------------------------------+
#property copyright "xiaoxin003"
#property link      "yangjx009@139.com"
#property version   "1.0"
#property strict

#include <Arrays\ArrayInt.mqh>
#include "inc\dictionary.mqh" //keyvalue数据字典类
#include "inc\trademgr.mqh"   //交易工具类
#include "inc\citems.mqh"     //交易组item


extern int       MagicNumber     = 180726;
extern double    Lots            = 0.05;
extern int       intTP           = 11;
extern int       intSL           = 6;            //止损点数，不用加0
extern double    distance        = 5;   //加仓间隔点数

extern double    levelTriggerHigh = 90;
extern double    levelTriggerLow  = 10;
extern double    levelOverBuy     = 80;
extern double    levelOverSell    = 20;

extern bool      isTrailingStop   = true;


int digits;
int       NumberOfTries   = 10,
          Slippage        = 5;
datetime  CheckTimeM1;
double    Pip;
CTradeMgr *objCTradeMgr;  //订单管理类
CDictionary *objDict = NULL;     //订单数据字典类
int tmp = 0;

int signalTriggerNum = 0;


string strOverProtectType = "none"; //none , stoch14 ,stoch100
double arrOverProtect[];
//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit()
{
//---
   Print("begin");
   digits=Digits;
   if(Digits==2 || Digits==4) Pip = Point;
   else if(Digits==3 || Digits==5) Pip = 10*Point;
   else if(Digits==6) Pip = 100*Point;
   if(objDict == NULL){
      objDict = new CDictionary();
      objCTradeMgr = new CTradeMgr(MagicNumber, Pip, NumberOfTries, Slippage);
   }
//---
   return(INIT_SUCCEEDED);
}
//+------------------------------------------------------------------+
//| Expert deinitialization function                                 |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
  {
//---
   Print("deinit");
  }
//+------------------------------------------------------------------+
//| Expert tick function                                             |
//+------------------------------------------------------------------+
string strSignal = "none";
void OnTick()
{
     if(isTrailingStop)MoveTrailingStop();
     subPrintDetails();
     checkEntry();
     if(CheckTimeM1==iTime(NULL,PERIOD_M1,0)){
         
     } else {
         signalTriggerNum += 1;
         if(strSignal == "none" || signalTriggerNum >= 7){
            strSignal = signal();
         }
         checkProtected();
         CheckTimeM1 = iTime(NULL,PERIOD_M1,0);
     }
 }

string signal()
{
   string sig = "none";
   double ma1,ma2;
   double stoch14;
   double stoch100;
   int j;
   bool isBuy1=false,isBuy2=false;
   bool isSell1=false,isSell2=false;
   ma1 = iMA(NULL,0,20,0,MODE_SMA,PRICE_CLOSE,1);
   ma2 = iMA(NULL,0,20,0,MODE_SMA,PRICE_CLOSE,2);
   if(Close[2]<ma2 && Close[1]>ma1){
      for(j=0;j<6;j++){
         stoch14 = iStochastic(NULL, PERIOD_M1, 14, 3, 3, MODE_SMA, 0, MODE_MAIN, j+1);
         if(stoch14 <= 10.999){
            isBuy1 = true;
         }
      }
      for(j=0;j<6;j++){
         stoch100 = iStochastic(NULL, PERIOD_M1, 100, 3, 3, MODE_SMA, 0, MODE_MAIN, j+1);
         if(stoch100 <= 10.999){
            isBuy2 = true;
         }
      }
      if(isBuy1 && isBuy2){
         sig = "buy3";
      }else if(isBuy1){
         sig = "buy1";
      }else if(isBuy2){
         sig = "buy2";
      }
   }
   if(Close[2]>ma2 && Close[1]<ma1){
      for(j=0;j<6;j++){
         stoch14 = iStochastic(NULL, PERIOD_M1, 14, 3, 3, MODE_SMA, 0, MODE_MAIN, j+1);
         if(stoch14 >= 89.9){
            isSell1 = true;
         }
      }
      for(j=0;j<6;j++){
         stoch100 = iStochastic(NULL, PERIOD_M1, 100, 3, 3, MODE_SMA, 0, MODE_MAIN, j+1);
         if(stoch100 >= 89.9){
            isSell2 = true;
         }
      }
      if(isSell1 && isSell2){
         sig = "sell3";
      }else if(isSell1){
         sig = "sell1";
      }else if(isSell2){
         sig = "sell2";
      }
      if(sig == "none"){
         
      }else{
         signalTriggerNum = 0;
      }
   }
   return sig;
}

void checkEntry(){
   if(objCTradeMgr.Total()>0)return ;
   
	double stoch14_1 = iStochastic(NULL, PERIOD_M1, 14, 3, 3, MODE_SMA, 0, MODE_MAIN, 1);
	double stoch14_2 = iStochastic(NULL, PERIOD_M1, 14, 3, 3, MODE_SMA, 0, MODE_MAIN, 2);
	double stoch100_1 = iStochastic(NULL, PERIOD_M1, 100, 3, 3, MODE_SMA, 0, MODE_MAIN, 1);
	double stoch100_2 = iStochastic(NULL, PERIOD_M1, 100, 3, 3, MODE_SMA, 0, MODE_MAIN, 2);
   double ma1 = iMA(NULL,0,20,0,MODE_SMA,PRICE_CLOSE,1);
   if((strSignal == "buy1" || strSignal == "buy2" || strSignal == "buy3") && stoch14_1>24 && stoch100_1>24){
      if((signalTriggerNum <3 && Ask - ma1<1*Pip) || (signalTriggerNum >=3 && Ask - ma1<2.5*Pip) ){
         objCTradeMgr.Buy(Lots, intSL, intTP, strSignal);
      }
   }
   
   if((strSignal == "sell1" || strSignal == "sell2" || strSignal == "sell3") && stoch14_1<76 && stoch100_1<76){
      if((signalTriggerNum <3 && ma1 - Bid<1*Pip) || (signalTriggerNum >=3 && ma1 - Bid <2.5*Pip) ){
         objCTradeMgr.Sell(Lots, intSL, intTP, strSignal);
      }
   }
}


void checkProtected(){
   if(objCTradeMgr.Total()<=0){
      if(ArraySize(arrOverProtect)>0){
         ArrayFree(arrOverProtect);
      }
      strOverProtectType = "none";
      return ;
   }
   int tradeTicket;
   string comment;
   int k;
   double sumVal,avgVal;
   double stoch14 = iStochastic(NULL, PERIOD_M1, 14, 3, 3, MODE_SMA, 0, MODE_MAIN, 1);
   double stoch100 = iStochastic(NULL, PERIOD_M1, 100, 3, 3, MODE_SMA, 0, MODE_MAIN, 1);
   for (int i=0; i<OrdersTotal(); i++) {
      if (OrderSelect(i, SELECT_BY_POS, MODE_TRADES)) {
         if(OrderSymbol()==Symbol() && OrderMagicNumber() == MagicNumber && OrderType() == OP_BUY){
            tradeTicket = OrderTicket();
            comment = OrderComment();
            if(comment == "buy1" || comment == "buy2" || comment == "buy3"){
               if(stoch100 >= 92){
                  if(strOverProtectType == "none"){
                     strOverProtectType = "stoch100";
                  }
               }else if(stoch14 >= 92){
                  if(strOverProtectType == "none"){
                     strOverProtectType = "stoch14";
                  }
               }
               
               if(strOverProtectType == "stoch100"){
                  ArrayResize(arrOverProtect, ArraySize(arrOverProtect)+1);
                  arrOverProtect[ArraySize(arrOverProtect)] = stoch100;
               }
               if(strOverProtectType == "stoch14"){
                  ArrayResize(arrOverProtect, ArraySize(arrOverProtect)+1);
                  arrOverProtect[ArraySize(arrOverProtect)] = stoch14;
               }
               if(ArraySize(arrOverProtect)>1){
                  sumVal  = 0;
                  for(k=0;k<ArraySize(arrOverProtect);k++){
                     sumVal = sumVal + arrOverProtect[k];
                  }
                  avgVal = sumVal/ArraySize(arrOverProtect);
                  if(avgVal < 85){
                     objCTradeMgr.Close(tradeTicket);
                  }
               }else if(ArraySize(arrOverProtect) == 1){
                  //TODO try to pertectd move sl
               }
               /*
               if(stoch100 >= 92 || stoch14 >= 92){
                  objCTradeMgr.Close(tradeTicket);
               }
               */
            }
         }
         if(OrderSymbol()==Symbol() && OrderMagicNumber() == MagicNumber && OrderType() == OP_SELL){
            tradeTicket = OrderTicket();
            comment = OrderComment();
            if(comment == "sell1" || comment == "sell2" || comment == "sell3"){
               
               if(stoch100 <= 8){
                  if(strOverProtectType == "none"){
                     strOverProtectType = "stoch100";
                  }
               }else if(stoch14 <= 8){
                  if(strOverProtectType == "none"){
                     strOverProtectType = "stoch14";
                  }
               }
               
               if(strOverProtectType == "stoch100"){
                  ArrayResize(arrOverProtect, ArraySize(arrOverProtect)+1);
                  arrOverProtect[ArraySize(arrOverProtect)] = stoch100;
               }
               if(strOverProtectType == "stoch14"){
                  ArrayResize(arrOverProtect, ArraySize(arrOverProtect)+1);
                  arrOverProtect[ArraySize(arrOverProtect)] = stoch14;
               }
               if(ArraySize(arrOverProtect)>1){
                  sumVal  = 0;
                  for(k=0;k<ArraySize(arrOverProtect);k++){
                     sumVal = sumVal + arrOverProtect[k];
                  }
                  avgVal = sumVal/ArraySize(arrOverProtect);
                  if(avgVal >15){
                     objCTradeMgr.Close(tradeTicket);
                  }
               }else if(ArraySize(arrOverProtect) == 1){
                  //TODO try to pertectd move sl
               }
               /*
               if(stoch100 <= 8 || stoch14 <= 8){
                  objCTradeMgr.Close(tradeTicket);
               }
               */
            }
         }
      }
   }
}



int getSL(){
  return intSL;
}

int getTP(){
  return intTP;
}

void subPrintDetails()
{
   //
   string sComment   = "";
   string sp         = "----------------------------------------\n";
   string NL         = "\n";

   sComment = sp;
   //sComment = sComment + "Net = " + TotalNetProfit() + NL; 
   sComment = sComment + sp;
   sComment = sComment + "Lots=" + DoubleToStr(Lots,2) + NL;
   sComment = sComment + sp;
   sComment = sComment + sp;
   sComment = sComment + "strSignal=" + strSignal +";"+ NL;
   
    
   
   Comment(sComment);
}

void MoveTrailingStop(){
   if(isTrailingStop){
     double newSL,newTP;
     double openPrice,myStopLoss,myTakeProfit;
     datetime dt,dtNow;
     for (int i=0; i<OrdersTotal(); i++) {
      if (OrderSelect(i, SELECT_BY_POS, MODE_TRADES)) {     
         if(OrderMagicNumber() == MagicNumber  && OrderSymbol() == Symbol()){

            if(OrderType() == OP_BUY ){
               //dt = OrderOpenTime();
               //dtNow = iTime(NULL,PERIOD_M1,1);
               openPrice = OrderOpenPrice();
               myStopLoss = OrderStopLoss();
               myTakeProfit = OrderTakeProfit();
               
               /*
               if(myStopLoss - openPrice < 8*Pip && Bid - openPrice >= 25*Pip){
                  newSL = openPrice + 8*Pip;
                  OrderModify(OrderTicket(),openPrice,newSL, OrderTakeProfit(), 0);
               }else if(myStopLoss - openPrice <5*Pip && Bid - openPrice >= 14*Pip){
                  newSL = openPrice + 5*Pip;
                  OrderModify(OrderTicket(),openPrice,newSL, OrderTakeProfit(), 0);
               }else if(myStopLoss - openPrice <0 && Bid - openPrice >= 10*Pip){
                  newSL = openPrice + 2*Pip;
                  OrderModify(OrderTicket(),openPrice,newSL, OrderTakeProfit(), 0);
               }else if(myStopLoss - openPrice <0 && Bid - openPrice >= 7*Pip){
                  newSL = openPrice - 5*Pip;
                  OrderModify(OrderTicket(),openPrice,newSL, OrderTakeProfit(), 0);
               }
               */
               if(myStopLoss - openPrice < 8*Pip && Bid - openPrice >= 22*Pip){
               
                  newSL = NormalizeDouble(openPrice + 8*Pip, Digits);
                  newTP = NormalizeDouble(myTakeProfit + (5*Pip),Digits);
                  OrderModify(OrderTicket(),openPrice,newSL, newTP, 0);
                  
               }else if(myStopLoss - openPrice <5*Pip && Bid - openPrice >= 14*Pip){
               
                  newSL = NormalizeDouble(openPrice + 5*Pip, Digits);
                  newTP = NormalizeDouble(myTakeProfit + (5*Pip),Digits);
                  OrderModify(OrderTicket(),openPrice,newSL, newTP, 0);
                  
               }else if(myStopLoss - openPrice <0 && Bid - openPrice >= 10*Pip){
               
                  newSL = NormalizeDouble(openPrice + 2*Pip, Digits);
                  newTP = NormalizeDouble(myTakeProfit + (5*Pip),Digits);
                  OrderModify(OrderTicket(),openPrice,newSL, newTP, 0);
                  
               }else if(openPrice - myStopLoss >intSL*Pip && Bid - openPrice >= 7*Pip){
               
                  newSL = NormalizeDouble(myStopLoss + (intSL-3)*Pip,Digits);
                  newTP = NormalizeDouble(myTakeProfit + (5*Pip),Digits);
                  OrderModify(OrderTicket(),openPrice,newSL, newTP, 0);
               }
               
               
               
            }
            if(OrderType() == OP_SELL){
              // dt = OrderOpenTime();
              // dtNow = iTime(NULL,PERIOD_M1,1);
               openPrice = OrderOpenPrice();
               myStopLoss = OrderStopLoss();
               myTakeProfit = OrderTakeProfit();
               /*
               if(openPrice - myStopLoss <8*Pip && openPrice - Ask  > 25*Pip){
                  newSL = openPrice - 8*Pip;
                  OrderModify(OrderTicket(),openPrice,newSL, OrderTakeProfit(), 0);
               }else if(openPrice - myStopLoss <5*Pip && openPrice - Ask  > 14*Pip){
                  newSL = openPrice - 5*Pip;
                  OrderModify(OrderTicket(),openPrice,newSL, OrderTakeProfit(), 0);
               }else if(openPrice - myStopLoss <0 && openPrice - Ask  > 10*Pip){
                  newSL = openPrice -2*Pip;
                  OrderModify(OrderTicket(),openPrice,newSL, OrderTakeProfit(), 0);
               }else if(openPrice - myStopLoss <0 && openPrice - Ask  > 7*Pip){
                  newSL = openPrice + 5*Pip;
                  OrderModify(OrderTicket(),openPrice,newSL, OrderTakeProfit(), 0);
               }
               */
               if(openPrice-myStopLoss < 8*Pip && openPrice-Ask >= 22*Pip){
               
                  newSL = NormalizeDouble(openPrice - 8*Pip, Digits);
                  newTP = NormalizeDouble(myTakeProfit - (5*Pip),Digits);
                  OrderModify(OrderTicket(),openPrice,newSL, newTP, 0);
                  
               }else if(openPrice -myStopLoss <5*Pip && openPrice -Ask >= 14*Pip){
               
                  newSL = NormalizeDouble(openPrice - 5*Pip, Digits);
                  newTP = NormalizeDouble(myTakeProfit - (5*Pip),Digits);
                  OrderModify(OrderTicket(),openPrice,newSL, newTP, 0);
                  
               }else if(myStopLoss - openPrice >0 && openPrice - Ask >= 10*Pip){
               
                  newSL = NormalizeDouble(openPrice - 2*Pip, Digits);
                  newTP = NormalizeDouble(myTakeProfit - (5*Pip),Digits);
                  OrderModify(OrderTicket(),openPrice,newSL, newTP, 0);
                  
               }else if(myStopLoss -openPrice >intSL*Pip && openPrice - Ask >= 7*Pip){
               
                  newSL = NormalizeDouble(myStopLoss - (intSL-3)*Pip,Digits);
                  newTP = NormalizeDouble(myTakeProfit - (5*Pip),Digits);
                  OrderModify(OrderTicket(),openPrice,newSL, newTP, 0);
               }
               
            }

         }
      }
     }
   }
}