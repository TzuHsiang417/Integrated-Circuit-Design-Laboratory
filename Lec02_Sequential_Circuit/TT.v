module TT(
    //Input Port
    clk,
    rst_n,
	in_valid,
    source,
    destination,

    //Output Port
    out_valid,
    cost
    );

input clk, rst_n, in_valid;
input [3:0] source;
input [3:0] destination;

output reg out_valid;
output reg [3:0] cost;

//==============================================//
//             Parameter and Integer            //
//==============================================//


//==============================================//
//            FSM State Declaration             //
//==============================================//

parameter READ = 2'b00, CALCULATE = 2'b01, RESULT = 2'b10, STANDBY = 2'b11;


//==============================================//
//                 reg declaration              //
//==============================================//
reg [15:0] Graph [15:0];
reg [3:0] first_station, end_station;
reg [1:0] c_state, n_state;

reg [15:0] last_station, unvisited;
reg [3:0] distance [15:0];

reg [3:0] round;

reg [15:0] viewing [15:0];

//==============================================//
//             Current State Block              //
//==============================================//

always@(posedge clk or negedge rst_n) 
begin
    if(!rst_n)
        c_state <= STANDBY; /* initial state */
    else 
        c_state <= n_state;
end

//==============================================//
//              Next State Block                //
//==============================================//

always@(*) begin
    case(c_state)
        READ:       if (!in_valid) n_state = CALCULATE;
                    else n_state = READ;
        CALCULATE:  if (distance[end_station] != 0 || last_station == 0) n_state = RESULT;        //check
                    else n_state = CALCULATE;
        RESULT:     if (rst_n) n_state = STANDBY;
                    else n_state = RESULT;
        STANDBY:    if (in_valid) n_state = READ;
                    else n_state = STANDBY;
    endcase
end

//==============================================//
//                  Input Block                 //
//==============================================//

always@(posedge clk or negedge rst_n) 
begin
    if(!rst_n)
    begin
        first_station <= 0;
        end_station <= 0;
    end
    else if(in_valid && (c_state == STANDBY))     //check
    begin
        first_station <= source;
        end_station <= destination;
    end    
    else
    begin
        first_station <= first_station;
        end_station <= end_station;
    end
end

integer i, n;
    
always@(posedge clk)
begin
    if(c_state == STANDBY)
        begin
            for(i=0; i<16; i=i+1)
            begin
                Graph[i] <= 0;
            end
        end
    else if(c_state == READ && in_valid == 1)
        begin
            Graph[source][destination] <= 1;
            Graph[destination][source] <= 1;
        end
    else
        begin
            for(n=0; n<16; n=n+1)
            begin
                Graph[n] <= Graph[n];
            end
        end
end

//==============================================//
//              Calculation Block               //
//==============================================//

integer l;
always@(*)
begin
    for(l=0; l<16; l=l+1)
    begin
        viewing[l] = last_station & Graph[l];
    end
end

integer m;
always@(posedge clk)
begin
    for(m=0; m<16; m=m+1)
    begin
        if(c_state == READ)
            last_station[first_station] <= 1'b1;
        else if(c_state == CALCULATE && distance[m] == round)
            last_station[m] <= 1'b1;
        else 
            last_station[m] <= 1'b0;
    end
end

integer j;
always@(negedge clk)
begin
    for(j=0; j<16; j=j+1)
    begin
        if(c_state == STANDBY)
            unvisited[j] <= 1;
        else if(c_state == READ)
            unvisited[first_station] <= 0;
        else if(c_state == CALCULATE && unvisited[j] == 1 && (viewing[j] != 0))
            unvisited[j] <= 0;
        else 
            unvisited[j] <= unvisited[j];
    end
end

integer k;
always@(negedge clk)
begin
    for(k=0; k<16; k=k+1)
    begin
        if(c_state == STANDBY)
            distance[k] <= 0;
        else if(c_state == READ)
            distance[first_station] <= 0;
        else if(c_state == CALCULATE && unvisited[k] == 1 && (viewing[k] != 0))
            distance[k] <= round;
        else 
            distance[k] <= distance[k];
    end
end

always@(posedge clk)
begin
    if(n_state == CALCULATE)
        round <= round + 1'b1;
    else if(c_state == READ || n_state == STANDBY)
        round <= 0;
    else 
        round <= round;
end

//==============================================//
//                Output Block                  //
//==============================================//

always@(posedge clk or negedge rst_n) 
begin
    if(!rst_n)
        out_valid <= 0; /* remember to reset */
    else if(n_state == RESULT)
        out_valid <= 1;
    else 
        out_valid <= 0;

end

always@(posedge clk or negedge rst_n) 
begin
    if(!rst_n)
        cost <= 0; /* remember to reset */
    else if(n_state == RESULT && distance[end_station] != 0)
        cost <= distance[end_station];
    else 
        cost <= 0;
end 

endmodule 

