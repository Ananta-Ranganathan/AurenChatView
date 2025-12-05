import type { HostComponent, ViewProps } from 'react-native';
import { CodegenTypes } from 'react-native';
export interface ThemeConfiguration {
    mode: string;
    color1: string;
    color2: string;
}
export interface ImageData {
    publicUrl?: string;
    original_filename?: string;
}
export interface Message {
    uuid: string;
    text: string;
    isUser: boolean;
    readByCharacterAt?: CodegenTypes.Double;
    isTypingIndicator?: boolean;
    image?: ImageData;
    reaction?: string;
}
export interface NativeProps extends ViewProps {
    messages: Message[];
    theme: ThemeConfiguration;
}
declare const _default: HostComponent<NativeProps>;
export default _default;
