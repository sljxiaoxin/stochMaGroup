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


extern int       MagicNumber     = 180725;
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
         //checkProtected();
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
      if((signalTriggerNum <3 && Ask - ma1<1*Pip) || (signalTriggerNum >=2 && Ask - ma1<4*Pip) ){
         objCTradeMgr.Buy(Lots, intSL, intTP, strSignal);
      }
   }
   
   if((strSignal == "sell1" || strSignal == "sell2" || strSignal == "sell3") && stoch14_1<76 && stoch100_1<76){
      if((signalTriggerNum <3 && ma1 - Bid<1*Pip) || (signalTriggerNum >=2 && ma1 - Bid <4*Pip) ){
         objCTradeMgr.Sell(Lots, intSL, intTP, strSignal);
      }
   }
}

void checkProtected(){
   if(objCTradeMgr.Total()<=0)return ;
   int tradeTicket;
   for (int i=0; i<OrdersTotal(); i++) {
      if (OrderSelect(i, SELECT_BY_POS, MODE_TRADES)) {
         if(OrderSymbol()==Symbol() && OrderMagicNumber() == MagicNumber && OrderType() == OP_BUY){
            tradeTicket = OrderTicket();
            if(strSignal == "buy1"){
               objCTradeMgr.Close(tradeTicket);
            }
            if(strSignal == "buy2"){
               objCTradeMgr.Close(tradeTicket);
            }
            if(strSignal == "buy3"){
               objCTradeMgr.Close(tradeTicket);
            }
         }
         if(OrderSymbol()==Symbol() && OrderMagicNumber() == MagicNumber && OrderType() == OP_SELL){
            tradeTicket = OrderTicket();
            if(strSignal == "sell1"){
               objCTradeMgr.Close(tradeTicket);
            }
            if(strSignal == "sell2"){
               objCTradeMgr.Close(tradeTicket);
            }
            if(strSignal == "sell3"){
               objCTradeMgr.Close(tradeTicket);
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
     double newSL;
     double openPrice,myStopLoss;
     datetime dt,dtNow;
     for (int i=0; i<OrdersTotal(); i++) {
      if (OrderSelect(i, SELECT_BY_POS, MODE_TRADES)) {     
         if(OrderMagicNumber() == MagicNumber  && OrderSymbol() == Symbol()){

            if(OrderType() == OP_BUY ){
               //dt = OrderOpenTime();
               //dtNow = iTime(NULL,PERIOD_M1,1);
               openPrice = OrderOpenPrice();
               myStopLoss = OrderStopLoss();
               
               //盈利超过2.5Pip则向上提止损
               if(myStopLoss - openPrice < 8*Pip && Bid - openPrice >= 25*Pip){
                  newSL = openPrice + 8*Pip;
                  OrderModify(OrderTicket(),openPrice,newSL, 0, 0);
               }else if(myStopLoss - openPrice <5*Pip && Bid - openPrice >= 14*Pip){
                  newSL = openPrice + 5*Pip;
                  OrderModify(OrderTicket(),openPrice,newSL, 0, 0);
               }else if(myStopLoss - openPrice <0 && Bid - openPrice >= 10*Pip){
                  newSL = openPrice + 2*Pip;
                  OrderModify(OrderTicket(),openPrice,newSL, 0, 0);
               }else if(myStopLoss - openPrice <0 && Bid - openPrice >= 7*Pip){
                  newSL = openPrice - 5*Pip;
                  OrderModify(OrderTicket(),openPrice,newSL, 0, 0);
               }
               
               
               
               
            }
            if(OrderType() == OP_SELL){
              // dt = OrderOpenTime();
              // dtNow = iTime(NULL,PERIOD_M1,1);
               openPrice = OrderOpenPrice();
               myStopLoss = OrderStopLoss();
               if(openPrice - myStopLoss <8*Pip && openPrice - Ask  > 25*Pip){
                  newSL = openPrice - 8*Pip;
                  OrderModify(OrderTicket(),openPrice,newSL, 0, 0);
               }else if(openPrice - myStopLoss <5*Pip && openPrice - Ask  > 14*Pip){
                  newSL = openPrice - 5*Pip;
                  OrderModify(OrderTicket(),openPrice,newSL, 0, 0);
               }else if(openPrice - myStopLoss <0 && openPrice - Ask  > 10*Pip){
                  newSL = openPrice -2*Pip;
                  OrderModify(OrderTicket(),openPrice,newSL, 0, 0);
               }else if(openPrice - myStopLoss <0 && openPrice - Ask  > 7*Pip){
                  newSL = openPrice + 5*Pip;
                  OrderModify(OrderTicket(),openPrice,newSL, 0, 0);
               }
               
               
            }

         }
      }
     }
   }
}