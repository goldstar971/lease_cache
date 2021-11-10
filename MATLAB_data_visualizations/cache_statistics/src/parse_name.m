% function [sub_data] = parse_name(data, filenames, search_string)
% 
% % preinitialize
% idx = zeros(size(filenames,1),1);
% %sub_d
% 
% % loop through all strings searching for partial matches
% for i = 1:size(filenames)
%     
%     if ( filenames(i)==search_string )
%         idx(i,1) = 1;
%         %sub_data = [sub_data
%     else
%         idx(i,1) = 0;
%     end
% end
% 
% sub_data = data(idx==1,:);
% 
% end
function [output,valid] =parse_name(x) 
a=bitshift(bitand(x,8),-3);
b=bitshift(bitand(x,4),-2);
c=bitshift(bitand(x,2),-1);
d=bitand(x,1);

output=bitor(bitor(a,b),bitshift(bitor(bitand(bitand(bitcmp(b),1),c),a),1));
valid=any([a,b,c,d]);
end
