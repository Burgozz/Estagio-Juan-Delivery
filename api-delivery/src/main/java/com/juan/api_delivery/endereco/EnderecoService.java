package com.juan.api_delivery.endereco;

import com.juan.api_delivery.usuario.Usuario;
import com.juan.api_delivery.usuario.UsuarioRepository;
import java.util.List;

import org.springframework.stereotype.Service;

import lombok.RequiredArgsConstructor;

import static com.juan.api_delivery.shared.exception.MensagensErro.USUARIO_NAO_ENCONTRADO;

@Service
@RequiredArgsConstructor
public class EnderecoService {

    private final EnderecoRepository repository;
    private final UsuarioRepository usuarioRepository;

    public List<Endereco> listarPorUsuario(Long usuarioId) {
        buscarUsuario(usuarioId);
        return repository.findByUsuarioId(usuarioId);
    }

    public Endereco criar(Long usuarioId, EnderecoDTO dto) {
        Usuario usuario = buscarUsuario(usuarioId);
        Endereco endereco = Endereco.builder()
            .rua(dto.getRua())
            .numero(dto.getNumero())
            .bairro(dto.getBairro())
            .cidade(dto.getCidade())
            .estado(dto.getEstado())
            .cep(dto.getCep())
            .usuario(usuario)
            .build();
        return repository.save(endereco);
    }

    public void deletar(Long id) {
        Endereco endereco = repository.findById(id)
            .orElseThrow(() -> new RuntimeException("Endereço não encontrado"));
        repository.delete(endereco);
    }

    private Usuario buscarUsuario(Long usuarioId) {
        return usuarioRepository.findById(usuarioId)
            .orElseThrow(() -> new RuntimeException(USUARIO_NAO_ENCONTRADO));
    }
}
