% speed test

times=zeros(1,10000);
Priority(1) %priotize PTB
for i=1:10000;
    times(i)=GetSecs;
end

subplot(2,1,1)
plot(times) %accommodating time for each loop step 

subplot(2,1,2)
plot(diff(times)) % time for each loop step